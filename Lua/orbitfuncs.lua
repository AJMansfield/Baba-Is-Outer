local function hyp(a, b)
    return math.sqrt(a*a + b*b)
local function leg(b, c)
    return math.sqrt(c*c - b*b)
end
local function round(x)
    return math.floor(x+0.5)
end

function orbitblock(onlystartblock_)
	local onlystartblock = onlystartblock_ or false
	
	local isorbit = {}
	
	if (onlystartblock == false) then
	    local isorbit = findfeature(nil,"orbit",nil,true)
	end
	
	if (isorbit ~= nil) then
		for h,j in ipairs(isorbit) do
			local allorbits = findall(j)
			
			if (#allorbits > 0) then
				for k,unitid in ipairs(allorbits) do
					if (issleep(unitid) == false) then
						local unit = mmf.newObject(unitid)
						local x,y,name,dir = unit.values[XPOS],unit.values[YPOS],unit.strings[UNITNAME],unit.values[DIR]
						local unitrules = {}
						
						if (unit.strings[UNITTYPE] == "text") then
							name = "text"
						end
						
						if (featureindex[name] ~= nil) then					
							for a,parentid in ipairs(featureindex[name]) do
								local baserule = parentid[1]
								local conds = parentid[2]
								
								local verb = baserule[2]
								
								if (verb == "orbit") then
									if testcond(conds,unitid) then
										table.insert(unitrules, parentid)
									end
								end
							end
						end
						
						local orbit = xthis(unitrules,name,"orbit")
						
						if (#orbit > 0) and (unit.flags[DEAD] == false) then
							
							for i,v in ipairs(orbit) do
								local these = findall({v})
								
								if (#these > 0) and (stophere == false) then
									for a,parentid in ipairs(these) do
										if (parentid ~= unit.fixed) and (stophere == false) then
											local parent = mmf.newObject(parentid)
											
											local px,py = parent.values[XPOS],parent.values[YPOS]
											
											local rx = x-px
											local ry = y-py
											local r = math.floor(hyp(rx, ry))

                                            local octant = math.floor(math.atan2(rx,ry) * 4 / math.pi) + 1

                                            local ox = 1
                                            local oy = 1
                                            dir, ox, oy = reversecheck(unitid,x,y,dir,ox,oy)

                                            if octant == 1 or octant == 8 then
                                                ry = ry + oy
                                                rx = round(leg(ry, r))
                                            elseif octant == 2 or octant == 3 then
                                                rx = rx - ox
                                                ry = round(leg(rx, r))
                                            elseif octant == 4 or octant == 5 then
                                                ry = ry - oy
                                                rx = round(leg(ry, r))
                                            elseif octant == 6 or octant == 7 then -- sixth and seventh octant
                                                rx = rx + ox
                                                ry = round(leg(rx, r))
                                            else
                                                error("Unknown Octant: "..table.concat({rx,ry,r,octant,dir,ox,oy},","))
                                            end

                                            local new_r = math.floor(hyp(rx, ry))
                                            assert(new_r == r, "Orbital Drift Detected: "..table.concat({rx,ry,r,octant,dir,ox,oy,new_r},","))

                                            local nx = x+rx
                                            local ny = y+ry

                                            update(unitid,nx,nyy,dir_)

										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end


function findorbits(unitid,orbittargets,x_,y_)
    -- duplicate of findfears
	local result,resultdir = false,4
	local amount = 0
	
	local ox,oy = 0,0
	local x,y = 0,0
	local name = ""
	local dir = 4
	
	if (unitid ~= 2) then
		local unit = mmf.newObject(unitid)
		x,y = unit.values[XPOS],unit.values[YPOS]
		name = getname(unit)
		dir = unit.values[DIR]
	else
		x,y = x_,y_
		name = "empty"
		dir = emptydir(x,y)
	end
	
	local orbitdirs = {}
	local maxorbit = 0
	
	for j=0,3 do
		local i = (((dir + 2) + j) % 4) + 1
		local ndrs = ndirs[i]
		ox = ndrs[1]
		oy = ndrs[2]
		
		local dirfound = false
		local diramount = 0
		
		if (#orbittargets > 0) then
			for a,v in ipairs(orbittargets) do
				local foundorbits = {}
				
				if (v ~= "empty") then
					foundorbits = findtype({v, nil},x+ox,y+oy,unitid)
				else
					local tileid = (x + ox) + (y + oy) * roomsizex
					if (unitmap[tileid] == nil) or (#unitmap[tileid] == 0) then
						foundorbits = {"a","b"}
					end
				end
				
				if (#foundorbits > 0) then
					dirfound = true
					result = true
					resultdir = rotate(i-1)
					diramount = diramount + 1
				end
			end
		end
		
		if dirfound then
			orbitdirs[i] = diramount
			maxorbit = math.max(maxorbit, diramount)
		else
			orbitdirs[i] = 0
		end
	end
	
	local totalorbitdirs = 0
	
	for i,v in ipairs(orbitdirs) do
		if (v >= maxorbit) then
			totalorbitdirs = totalorbitdirs + 1
		else
			orbitdirs[i] = 0
		end
	end
	
	if (totalorbitdirs > 0) then
		amount = maxorbit
	end
	
	if (totalorbitdirs > 1) then
		resultdir = dir
		local searching = true
		local tests = 0
		
		while searching do
			local problems = false
			
			if (orbitdirs[resultdir+1] == 1) then
				problems = true
			else
				local ndrs = ndirs[resultdir+1]
				local ox,oy = ndrs[1],ndrs[2]
				
				local obs = check(unitid,x,y,resultdir)
				
				local obsresult = 0
				for i,v in ipairs(obs) do
					if (v == 1) or (v == -1) then
						obsresult = 1
						break
					elseif (v ~= 0) and (obsresult == 0) then
						obsresult = v
					end
				end
				
				if (obsresult == 1) then
					problems = true
				elseif (obsresult ~= 0) then
					local ndrs = ndirs[resultdir+1]
					local ox,oy = ndrs[1],ndrs[2]
					
					local obsresult_ = trypush(obsresult,ox,oy,resultdir,false,x,y,"orbit",unitid)
					
					if (obsresult_ ~= 0) then
						problems = true
					end
				end
			end
			
			if (problems == false) then
				searching = false
			else
				if (tests == 0) then
					resultdir = (resultdir - 1 + 4) % 4
				elseif (tests == 1) then
					resultdir = (resultdir + 2 + 4) % 4
				elseif (tests == 2) then
					resultdir = (resultdir + 1 + 4) % 4
				elseif (tests == 3) then
					resultdir = (resultdir - 2 + 4) % 4
				end
				
				tests = tests + 1
			end
			
			if (tests >= 4) then
				searching = false
				result = false
				resultdir = 4
			end
		end
	end
	
	return result,resultdir,amount
end