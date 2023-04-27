local function hyp(a, b)
    return math.sqrt(a*a + b*b)
end
local function leg(b, c)
    return math.sqrt(c*c - b*b)
end
local function round(x)
    return math.floor(x+0.5)
end
local function step_x(steps, rx, nx)
	if nx > rx then
		table.insert(steps, 0)
	elseif nx < rx then
		table.insert(steps, 2)
	end
end
local function step_y(steps, ry, ny)
	if ny > ry then
		table.insert(steps, 3)
	elseif ny < ry then
		table.insert(steps, 1)
	end
end

function calc_orbit_step(rx,ry, reverse)
	local steps = {}
	local r = math.floor(hyp(rx, ry))
	local octant = math.floor(math.atan2(rx,ry) * 4 / math.pi) + 1

	local nx, ny = rx, ry

	if reverse then
		octant = octant + 4
	end

	if octant == 1 or octant == 8 then
		ny = ry + 1
		nx = round(leg(ry, r))
		step_y(steps, ry,ny)
		step_x(steps, rx,nx)
	elseif octant == 2 or octant == 3 then
		nx = rx - 1
		ny = round(leg(rx, r))
		step_x(steps, rx,nx)
		step_y(steps, ry,ny)
	elseif octant == 4 or octant == 5 then
		ny = ry - 1
		nx = round(leg(ry, r))
		step_y(steps, ry,ny)
		step_x(steps, rx,nx)
	elseif octant == 6 or octant == 7 then
		nx = rx + 1
		ny = round(leg(rx, r))
		step_x(steps, rx,nx)
		step_y(steps, ry,ny)
	else
		error("Unknown Octant: "..table.concat({rx,ry,r,octant,dir,ox,oy},","))
	end

	local new_r = math.floor(hyp(nx, ny))
	assert(new_r == r, "Orbital Drift Detected: "..table.concat({rx,ry,r,octant,nx,ny,new_r},","))

	return steps
end


function orbit_take(moving_units, ...)
	local orbit_rules = findfeature(nil,"orbit",nil,true)
	if (orbit_rules == nil) then
		return
	end

	vprint("orbit_rules", orbit_rules)

	for rule_idx, rule_id in ipairs(orbit_rules) do
		handle_orbit_rule(rule_id, moving_units, unpack(arg) )
	end
end
function handle_orbit_rule(rule_id, ...)
	vprint("rule_id", rule_id)

	local lhs_list = findall(rule_id)

	vprint("lhs_list", lhs_list)

	if (#lhs_list == 0) then
		print("no lhs objects found")
		return
	end
end
		-- 	for k,unitid in ipairs(allorbits) do
		-- 		if (issleep(unitid) == false) then
		-- 			local unit = mmf.newObject(unitid)
		-- 			local x,y,name,dir = unit.values[XPOS],unit.values[YPOS],unit.strings[UNITNAME],unit.values[DIR]
		-- 			local unitrules = {}
					
		-- 			if (unit.strings[UNITTYPE] == "text") then
		-- 				name = "text"
		-- 			end
					
		-- 			if (featureindex[name] ~= nil) then					
		-- 				for a,parentid in ipairs(featureindex[name]) do
		-- 					local baserule = parentid[1]
		-- 					local conds = parentid[2]
							
		-- 					local verb = baserule[2]
							
		-- 					if (verb == "orbit") then
		-- 						if testcond(conds,unitid) then
		-- 							table.insert(unitrules, parentid)
		-- 						end
		-- 					end
		-- 				end
		-- 			end
					
		-- 			local orbit = xthis(unitrules,name,"orbit")
					
		-- 			if (#orbit > 0) and (unit.flags[DEAD] == false) then
						
		-- 				for i,v in ipairs(orbit) do
		-- 					local these = findall({v})
							
		-- 					if (#these > 0) and (stophere == false) then
		-- 						for a,parentid in ipairs(these) do
		-- 							if (parentid ~= unit.fixed) and (stophere == false) then
		-- 								local parent = mmf.newObject(parentid)
										
		-- 								local px,py = parent.values[XPOS],parent.values[YPOS]
										
		-- 								local rx = x-px
		-- 								local ry = y-py
		-- 								local r = math.floor(hyp(rx, ry))

		-- 								local octant = math.floor(math.atan2(rx,ry) * 4 / math.pi) + 1

		-- 								local ox = 1
		-- 								local oy = 1
		-- 								dir, ox, oy = reversecheck(unitid,x,y,dir,ox,oy)

		-- 								if octant == 1 or octant == 8 then
		-- 									ry = ry + oy
		-- 									rx = round(leg(ry, r))
		-- 								elseif octant == 2 or octant == 3 then
		-- 									rx = rx - ox
		-- 									ry = round(leg(rx, r))
		-- 								elseif octant == 4 or octant == 5 then
		-- 									ry = ry - oy
		-- 									rx = round(leg(ry, r))
		-- 								elseif octant == 6 or octant == 7 then -- sixth and seventh octant
		-- 									rx = rx + ox
		-- 									ry = round(leg(rx, r))
		-- 								else
		-- 									error("Unknown Octant: "..table.concat({rx,ry,r,octant,dir,ox,oy},","))
		-- 								end

		-- 								local new_r = math.floor(hyp(rx, ry))
		-- 								assert(new_r == r, "Orbital Drift Detected: "..table.concat({rx,ry,r,octant,dir,ox,oy,new_r},","))

		-- 								local nx = x+rx
		-- 								local ny = y+ry

		-- 								update(unitid,nx,nyy,dir_)

		-- 							end
		-- 						end
		-- 					end
		-- 				end
		-- 			end
		-- 		end
		-- 	end
		-- end


table.insert(mod_hook_functions["movement_take"], orbit_take)

function vprint(name, value)
	if  type(value) == "table" then
		print(name .. " = ")
		tprint(value, 1)
	elseif type(value) == 'boolean' then
	  print(name .. " = " .. tostring(value))
	else
	  print(name .. " = " .. value)
	end
end
function tprint (tbl, indent)
	if not indent then indent = 0 end
	for k, v in pairs(tbl) do
	  formatting = string.rep("  ", indent) .. k .. ": "
	  if type(v) == "table" then
		print(formatting)
		tprint(v, indent+1)
	  elseif type(v) == 'boolean' then
		print(formatting .. tostring(v))      
	  else
		print(formatting .. v)
	  end
	end
  end