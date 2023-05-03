
function is_number_word(word)
    for i = 1, #word do
        if not string.find("0123456789", string.sub(word,i,i), 1, true) then
            return false
        end
    end
    return true
end

function make_relevant_number_word_list(word)
    local result = {}
    if is_number_word(word) then
        local alphabet = "0123456789"
        table.insert(result, word)
        for i = 1, #alphabet do
            local letter = string.sub(alphabet,i,i)
            table.insert(result, word..letter)
        end
    end
    return result
end

-- function rule_update_after_hook_dump_info()
--     vprint("wordunits",wordunits)
--     vprint("wordrelatedunits",wordrelatedunits)
--     vprint("letterunits_map",letterunits_map)
--     vprint("codeunits",codeunits)
--     vprint("features",features)
--     vprint("featureindex",featureindex)
--     vprint("condfeatureindex",condfeatureindex)
--     vprint("visualfeatures",visualfeatures)
--     vprint("notfeatures",notfeatures)
--     vprint("groupfeatures",groupfeatures)
-- end
-- table.insert(mod_hook_functions.rule_update_after, rule_update_after_hook_dump_info)
local old_formlettermap = formlettermap
function formlettermap()
    old_formlettermap()
    formnumbermap()
end

function formnumbermap()
	local digitmap = {}
	local digitunitlist = {}
	
	if (#letterunits > 0) then
		for i,unitid in ipairs(letterunits) do
			local unit = mmf.newObject(unitid)
			
			if (unit.values[TYPE] == 5) and (unit.flags[DEAD] == false) then
				local x,y = unit.values[XPOS],unit.values[YPOS]
				local tileid = x + y * roomsizex
				
				local name = string.sub(unit.strings[UNITNAME], 6)

                if is_number_word(name) then
				
                    if (digitmap[tileid] == nil) then
                        digitmap[tileid] = {}
                    end

                    table.insert(digitmap[tileid], {name, unitid})
                end
			end
		end
		
		for tileid,v in pairs(digitmap) do
			local x = math.floor(tileid % roomsizex)
			local y = math.floor(tileid / roomsizex)
			
			local ux,uy = x,y-1
			local lx,ly = x-1,y
			local dx,dy = x,y+1
			local rx,ry = x+1,y
			
			local tidr = rx + ry * roomsizex
			local tidu = ux + uy * roomsizex
			local tidl = lx + ly * roomsizex
			local tidd = dx + dy * roomsizex
			
			local continuer = false
			local continued = false
			
			if (digitmap[tidr] ~= nil) then
				continuer = true
			end
			
			if (digitmap[tidd] ~= nil) then
				continued = true
			end
			
			
			if (digitmap[tidl] == nil) then
				digitunitlist = formdigitunits(x,y,digitmap,1,digitunitlist)
			end
			
			if (digitmap[tidu] == nil) then
				digitunitlist = formdigitunits(x,y,digitmap,2,digitunitlist)
			end
		end
		
		for i,v in ipairs(digitunitlist) do
			local x = v[3]
			local y = v[4]
			local w = v[6]
			local dir = v[5]
			
			local dr = dirs[dir]
			local ox,oy = dr[1],dr[2]
			
			--[[
			MF_debug(x,y,1)
			MF_alert("In database: " .. v[1] .. ", dir " .. tostring(v[5]))
			]]--
			
			local tileid = x + y * roomsizex
			
			if (letterunits_map[tileid] == nil) then
				letterunits_map[tileid] = {}
			end
			
			table.insert(letterunits_map[tileid], {v[1], v[2], v[3], v[4], v[5], v[6], v[7]})
			
			if (w > 1) then
				local endtileid = (x + ox * (w - 1)) + (y + oy * (w - 1)) * roomsizex
				
				if (letterunits_map[endtileid] == nil) then
					letterunits_map[endtileid] = {}
				end
				
				table.insert(letterunits_map[endtileid], {v[1], v[2], v[3], v[4], v[5], v[6], v[7]})
			end
		end
	end
end


function formdigitunits(x,y,digitmap,dir,database_)
	local dr = dirs[dir]
	local ox,oy = dr[1],dr[2]
	local cx,cy = x,y
	
	local jumble = {}
	local jumblecombo = {}
	local totalcombos = 1
	local done = false
	
	local database = database_
	
	while (done == false) do
		local tileid = cx + cy * roomsizex
		
		if (digitmap[tileid] ~= nil) then
			table.insert(jumble, {})
			local cjumble = jumble[#jumble]
			
			for i,v in ipairs(digitmap[tileid]) do
				table.insert(cjumble, {v[1], v[2]})
			end
			
			table.insert(jumblecombo, 0)
			totalcombos = totalcombos * #cjumble
			
			cx = cx + ox
			cy = cy + oy
		else
			done = true
		end
	end
	
	local been_seen = {}

    local required_length = #jumble
	
	if (#jumble > 0) then
		for j=1,totalcombos do
			local word = ""
			local subword = ""
			local prevword = ""
			local prevwordid = 0
			local wordids = {}
			local branches = {}
			local offset = 0
			local updatecombo = true
			
			for i,cjumble in ipairs(jumble) do
				local ccombo = jumblecombo[i] + 1
				local cword = cjumble[ccombo]
				
				word = word .. cword[1]
				table.insert(wordids, cword[2])
				
				if (i > 1) then
					subword = prevword .. cword[1]
				end
				
				if updatecombo then
					jumblecombo[i] = jumblecombo[i] + 1
					
					if (jumblecombo[i] >= #cjumble) then
						jumblecombo[i] = 0
						updatecombo = true
					else
						updatecombo = false
					end
				end
				
				local found,fullwords,partwords = finddigitwords(word,i - 1,subword)
				
				for a,b in ipairs(partwords) do
					table.insert(branches, {prevword, i - 2, false, {prevwordid}})
				end
				
				prevword = cword[1]
				prevwordid = cword[2]
				
				-- MF_alert(tostring(j) .. " Currently " .. word .. ", " .. subword .. ", " .. prevword .. ", " .. tostring(dir))
				
				for a,b in ipairs(branches) do
					local w = b[1]
					local pos = b[2]
					local dead = b[3]
					local wids = b[4]
					
					w = w .. cword[1]
					b[1] = w
					
					table.insert(b[4], cword[2])
					
					if (dead == false) then
						local sfound,sfullwords = finddigitwords(w,i - 1,nil,false)
						
						if (sfound == false) then
							b[3] = true
							
							if (#b[4] > 0) then
								table.remove(b[4], #b[4])
							end
						else
							if (#sfullwords > 0) then
								for c,d in ipairs(sfullwords) do
									local w = d[1]
									local t = d[2]
									local wordcode = w .. tostring(pos)
									
									local fwids = {}
									for c,d in ipairs(b[4]) do
										table.insert(fwids, d)
									end
									
									if (been_seen[wordcode] == nil) then
										been_seen[wordcode] = 1
										
                                        if #w >= required_length then
                                            table.insert(database, {w, t, x + ox * pos, y + oy * pos, dir, #fwids, fwids})
                                        end
									end
								end
							end
						end
					end
				end
				
				if (found == false) then
					if (string.len(word) > 0) and (#wordids > 0) then
						word = string.sub(word, -1)
						
						local wid = wordids[#wordids]
						wordids = {wid}
						
						offset = i - 1
					end
				else
					if (#fullwords > 0) then
						for a,b in ipairs(fullwords) do
							local w = b[1]
							local t = b[2]
							local pos = b[3]
							local fulloffset = offset + pos
							local wordcode = w .. tostring(fulloffset)
							
							local fwids = {}
							for c,d in ipairs(wordids) do
								table.insert(fwids, d)
							end
							
							if (been_seen[wordcode] == nil) then
								been_seen[wordcode] = 1
								
								--MF_alert("Adding to database: " .. w .. ", " .. tostring(dir) .. ", " .. wordcode)
                                if #w >= required_length then
                                    table.insert(database, {w, t, x + ox * fulloffset, y + oy * fulloffset, dir, #fwids, fwids})
                                end
							end
						end
					end
				end
			end
		end
	end
	
	return database
end


function finddigitwords(word_,wordpos_,subword_,mainbranch_)
	local word = word_
	local subword = subword_
	local wordpos = wordpos_ or 0
	local mainbranch = true
	local found = false
	local foundsub = false
	local fullnums = {}
	local newbranches = {}
	
	if (mainbranch_ ~= nil) then
		mainbranch = mainbranch_
	end
	
	local result = {}
	local relevant_number_word_list = make_relevant_number_word_list(word)
	if (string.len(word) > 0) then
		for i,c in pairs(relevant_number_word_list) do
			if (c ~= 1) and (string.len(tostring(c)) > 0) then
				local name = c
				
				if (string.len(name) > 5) and (string.sub(name, 1, 5) == "text_") then
					name = string.sub(name, 6)
				end
				
				if (string.len(word) <= string.len(name)) and (string.sub(name, 1, string.len(word)) == word) then
					if (string.len(word) == string.len(name)) then
						table.insert(fullnums, {name, 0})
						found = true
					else
						found = true
					end
				end
				
				if (wordpos > 0) and (string.len(word) >= 2) and mainbranch then
					if (string.len(name) >= string.len(subword)) and (string.sub(name, 1, string.len(subword)) == subword) then
						table.insert(newbranches, {subword, wordpos})
						foundsub = true
					end
				end
			end
		end
	end
	
	if (string.len(word) <= 1) then
		found = true
	end
	
	if (#fullnums > 0) then
		for i,v in ipairs(fullnums) do
			if (word == v[1]) then
				table.insert(result, {v[1], 2, v[2]})
			end
		end
	end
	
	return found,result,newbranches
end