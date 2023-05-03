
function is_number_word(word)
    for i = 1, #word do
        if string.find(string.sub(word,i,i), "0123456789") == nil then
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

function findletterwords(word_,wordpos_,subword_,mainbranch_)
	local word = word_
	local subword = subword_
	local wordpos = wordpos_ or 0
	local mainbranch = true
	local found = false
	local foundsub = false
	local fullwords = {}
	local fullwords_c = {}
	local fullwords_nums = {}
	local newbranches = {}
	
	if (mainbranch_ ~= nil) then
		mainbranch = mainbranch_
	end
	
	local result = {}
	
	if (string.len(word) > 1) then
		for i,v in pairs(unitreference) do
			local name = i
			
			if (string.len(name) > 5) and (string.sub(name, 1, 5) == "text_") then
				name = string.sub(name, 6)
			end
			
			if (string.len(word) <= string.len(name)) and (string.sub(name, 1, string.len(word)) == word) then
				if (string.len(word) == string.len(name)) then
					table.insert(fullwords, {name, 0})
					found = true
				else
					found = true
				end
			end
			
			if (wordpos > 0) and (string.len(word) >= 2) and mainbranch then
				if (string.len(name) >= string.len(subword)) and (string.sub(name, 1, string.len(subword)) == subword) then
					--[[
					if (subword == name) then
						table.insert(fullwords, {name, wordpos + 1})
						foundsub = true
					else
						table.insert(newbranches, {subword, wordpos})
						foundsub = true
					end
					]]--
					
					table.insert(newbranches, {subword, wordpos})
					foundsub = true
				end
			end
		end
	end
	
	if (string.len(word) > 0) then
		for c,d in pairs(cobjects) do
			if (c ~= 1) and (string.len(tostring(c)) > 0) then
				local name = c
				
				if (string.len(name) > 5) and (string.sub(name, 1, 5) == "text_") then
					name = string.sub(name, 6)
				end
				
				if (string.len(word) <= string.len(name)) and (string.sub(name, 1, string.len(word)) == word) then
					if (string.len(word) == string.len(name)) then
						table.insert(fullwords_c, {name, 0})
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

    local relevant_number_words = make_relevant_number_word_list(word)
    for i, number_word in pairs(relevant_number_words) do
        if (string.len(number_word) > 0) then
            local name = number_word
            
            if (string.len(name) > 5) and (string.sub(name, 1, 5) == "text_") then
                name = string.sub(name, 6)
            end
            
            if (string.len(word) <= string.len(name)) and (string.sub(name, 1, string.len(word)) == word) then
                if (string.len(word) == string.len(name)) then
                    table.insert(fullwords_nums, {name, 0})
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
	
	if (string.len(word) <= 1) then
		found = true
	end
	
	if (#fullwords > 0) then
		for i,v in ipairs(fullwords) do
			local text = v[1]
			local textpos = v[2]
			local alttext = "text_" .. text
			
			local name_base = unitreference[text]
			local name_general = objectpalette[text]
			local altname_base = unitreference[alttext]
			local altname_general = objectpalette[alttext]
			
			local realname = altname_general
			local realname_general = name_general
			
			if (generaldata.strings[WORLD] == generaldata.strings[BASEWORLD]) then
				realname = altname_base
				realname_general = name_base
			end
			
			if (realname ~= nil) then
				local name = getactualdata_objlist(realname,"name")
				local wtype = getactualdata_objlist(realname,"type")
				
				if (name == text) or (name == alttext) then
					if (wtype ~= 5) then
						if (realname_general ~= nil) then
							objectlist[text] = 1
						elseif (((text == "all") or (text == "empty")) and (realname ~= nil)) then
							objectlist[text] = 1
						end
						
						table.insert(result, {name, wtype, textpos})
					end
				end
			end
		end
	end
	
	if (#fullwords_c > 0) then
		for i,v in ipairs(fullwords_c) do
			if (word == v[1]) then
				table.insert(result, {v[1], 8, v[2]})
			end
		end
	end

    if (#fullwords_nums > 0) then
		for i,v in ipairs(fullwords_nums) do
			if (word == v[1]) then
				table.insert(result, {v[1], 8, v[2]})
			end
		end
	end
	
	return found,result,newbranches
end