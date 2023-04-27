

cached_tangent_moves = {}
function orbit_take(moving_units, been_seen)
	local lhs_names = findfeature(nil,"orbit",nil,true)
	if (lhs_names == nil) then
		return
	end

	vprint("orbit_rules", lhs_names)

	for i, lhs_name in ipairs(lhs_names) do
		orbit_each_lhs_name_around(lhs_name, moving_units, been_seen)
	end

	
	vprint("moving_units", moving_units)
end
table.insert(mod_hook_functions["movement_take"], orbit_take)

-- function orbit_tangent_take(moving_units, been_seen)
-- 	local lhs_names = findfeature(nil,"orbit",nil,true)
-- 	if (lhs_names == nil) then
-- 		return
-- 	end

-- 	vprint("orbit_rules", lhs_names)

-- 	for i, lhs_name in ipairs(lhs_names) do
-- 		orbit_each_lhs_name_around(lhs_name, moving_units, been_seen)
-- 	end

	
-- 	vprint("moving_units", moving_units)
-- end
-- table.insert(mod_hook_functions["movement_take"], orbit_tangent_take)

function bsid_key(move)
	local hashcode = 0
	
	hashcode = hashcode + move.unitid
	hashcode = hashcode * 2
	if move.reason == "orbit_radius" then
		hashcode = hashcode + 2000
	end
	return hashcode
end

function insert_move(move, moving_units, been_seen)
	print("Inserting Move!")
	vprint("new move", move)
	local bsid = bsid_key(move)
	vprint("bsid", bsid)
	if move.dir < 0 then
		return
	end
	if been_seen[bsid] == nil then
		table.insert(moving_units, move)
		been_seen[bsid] = #moving_units
		vprint("key", #moving_units)
	else
		local key = been_seen[bsid]
		vprint("key", key)
		local this = moving_units[key]
		vprint("existing", this)
		if this == nil then
			moving_units[key] = move
		elseif this.dir == move.dir then
			this.moves = this.moves + move.moves
		elseif this.dir == reversedir(move.dir) then
			if this.moves > move.moves then
				this.moves = this.moves - move.moves
			elseif this.moves == move.moves then
				moving_units[key] = nil
			elseif this.moves < move.moves then
				move.moves = move.moves - this.moves
				moving_units[key] = move
			end
		end
		vprint("final", moving_units[key])
	end
end


function orbit_each_lhs_name_around(lhs_name, moving_units, been_seen)
	vprint("lhs_name", lhs_name)

	local lhs_uid_list = findall(lhs_name)

	vprint("lhs_uid_list", lhs_uid_list)

	if (#lhs_uid_list == 0) then
		print("no lhs objects found")
		return
	end

	for i,lhs_uid in ipairs(lhs_uid_list) do
		orbit_each_lhs_around(lhs_uid, moving_units, been_seen)
	end
end
function orbit_each_lhs_around(lhs_uid, moving_units, been_seen)
	vprint("lhs_uid", lhs_uid)
	if issleep(lhs_uid) then
		return
	end

	local lhs_unit = mmf.newObject(lhs_uid)

	if lhs_unit.flags[DEAD] then
		return
	end
	
	vprint("lhs_unit", lhs_unit)
	local lhs_name =lhs_unit.strings[UNITNAME]
	local applicable_rules = {}

	if (lhs_unit.strings[UNITTYPE] == "text") then
		lhs_name = "text"
	end

	vprint("featureindex["..lhs_name.."]", featureindex[lhs_name])

	if (featureindex[lhs_name] ~= nil) then					
		for i,rule_info in ipairs(featureindex[lhs_name]) do
			local rule_main = rule_info[1]
			local rule_pred = rule_info[2]
			
			local verb = rule_main[2]
			
			if (verb == "orbit") then
				if testcond(rule_pred, lhs_uid) then
					table.insert(applicable_rules, rule_info)
				end
			end
		end
	end

	vprint("applicable_rules", applicable_rules)

	local rhs_names = xthis(applicable_rules, lhs_name, "orbit")

	for i,rhs_name in ipairs(rhs_names) do
		orbit_each_lhs_around_rhs_name(lhs_uid, rhs_name, moving_units, been_seen)
	end

end
function orbit_each_lhs_around_rhs_name(lhs_uid, rhs_name, moving_units, been_seen)
	local rhs_uid_list = findall({rhs_name})
	vprint("rhs_uid_list", rhs_uid_list)
	
	for i,rhs_uid in ipairs(rhs_uid_list) do
		orbit_each_lhs_around_rhs(lhs_uid, rhs_uid, moving_units, been_seen)
	end
end
function orbit_each_lhs_around_rhs(lhs_uid, rhs_uid, moving_units, been_seen)
	local lhs_unit = mmf.newObject(lhs_uid)
	local rhs_unit = mmf.newObject(rhs_uid)

	local lx,ly,ld = lhs_unit.values[XPOS],lhs_unit.values[YPOS],lhs_unit.values[DIR]
	local rx,ry,rd = rhs_unit.values[XPOS],rhs_unit.values[YPOS],rhs_unit.values[DIR]

	local lhs_is_reverse = (reversecheck(lhs_uid,ld,lx,ly) ~= ld)
	vprint("lhs_is_reverse", lhs_is_reverse)

	local tangent_step, radius_step = calc_orbit_step(lx-rx, ly-ry, lhs_is_reverse)

	if isstill_or_locked(lhs_uid, lx, ly, ld) == false then
		insert_move({unitid = lhs_uid, reason = "orbit_tangent", state = 0, moves = 1, dir = tangent_step, xpos = lx, ypos = ly}, moving_units, been_seen)
		insert_move({unitid = lhs_uid, reason = "orbit_radius", state = 0, moves = 1, dir = radius_step, xpos = lx, ypos = ly}, moving_units, been_seen)
	end
end


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
		return 0
	elseif nx < rx then
		return 2
	else
		return -1
	end
end
local function step_y(steps, ry, ny)
	if ny > ry then
		return 3
	elseif ny < ry then
		return 1
	else
		return -1
	end
end
local function calc_octant(x, y)
	-- math.floor(math.atan2(ry,rx) * 4 / math.pi)
	local angle = math.atan2(y,x)
	angle = math.fmod(angle + math.pi * 2, math.pi * 2)
	local result = math.floor(angle * 4 / math.pi ) + 1
	local ax, ay = math.abs(x), math.abs(y)

	-- handle boundaries correctly:
	if x == 0 and y == 0 then
		result = -1
	elseif y == 0 then
		if x > 0 then
			result = 1
		elseif x < 0 then
			result = 5
		end
	elseif x == 0 then
		if y > 0 then
			result = 3
		elseif x < 0 then
			result = 7
		end
	elseif ax == ay then
		if x > 0 and y > 0 then
			result = 2
		elseif x < 0 and y > 0 then
			result = 4
		elseif x < 0 and y < 0 then
			result = 6
		elseif x > 0 and y < 0 then
			result = 8
		end
	end
	
	vprint("x", x)
	vprint("y", y)
	vprint("octant", result)

	return result
end
function calc_orbit_step(rx,ry, reverse)
	local tangent_step = -1
	local radius_step = -1
	local r = math.floor(hyp(rx, ry))
	local octant = calc_octant(rx, ry)
	
	vprint("rx", rx)
	vprint("ry", ry)
	vprint("r", r)
	vprint("octant", octant)

	local nx, ny = rx, ry

	if reverse then
		d = -1
	else
		d = 1
	end

	if octant == 1 or octant == 8 then
		ny = ry + d
		nx = round(leg(ry, r))
		tangent_step = step_y(steps, ry,ny)
		radius_step = step_x(steps, rx,nx)
	elseif octant == 2 or octant == 3 then
		nx = rx - d
		ny = round(leg(rx, r))
		tangent_step = step_x(steps, rx,nx)
		radius_step = step_y(steps, ry,ny)
	elseif octant == 4 or octant == 5 then
		ny = ry - d
		nx = round(leg(ry, r))
		tangent_step = step_y(steps, ry,ny)
		radius_step = step_x(steps, rx,nx)
	elseif octant == 6 or octant == 7 then
		nx = rx + d
		ny = round(leg(rx, r))
		tangent_step = step_x(steps, rx,nx)
		radius_step = step_y(steps, ry,ny)
	else
		vprint("Unknown Octant ", {rx,ry,r,octant})
	end

	local new_r = math.floor(hyp(nx, ny))
	if (new_r ~= r) then
		vprint("Orbital Drift Detected ", {rx,ry,r,octant,nx,ny,new_r})
	end

	return tangent_step, radius_step
end



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

-- function test_octant_func()
-- 	print("testing octant centers (should be 1 2 3 4 5 6 7 8)")
-- 	calc_octant(2,1)
-- 	calc_octant(1,2)
-- 	calc_octant(-1,2)
-- 	calc_octant(-2,1)
-- 	calc_octant(-2,-1)
-- 	calc_octant(-1,-2)
-- 	calc_octant(1,-2)
-- 	calc_octant(2,-1)

-- 	print("testing octant edges (should still be 1 2 3 4 5 6 7 8)")
-- 	calc_octant(1,0)
-- 	calc_octant(1,1)
-- 	calc_octant(0,1)
-- 	calc_octant(-1,1)
-- 	calc_octant(-1,0)
-- 	calc_octant(-1,-1)
-- 	calc_octant(0,-1)
-- 	calc_octant(1,-1)
-- end
-- test_octant_func()