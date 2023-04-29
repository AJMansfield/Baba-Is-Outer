-- require("Lua.utils")


cached_principal = {}
cached_residual = {}

function orbit_principal_take(moving_units, been_seen)
	cached_principal, cached_residual = derive_orbit_takes()

	update_dirs(cached_principal)
	for i, move in pairs(cached_principal) do
		table.insert(moving_units, move)
	end

	-- print("Submitting Principal Moves.")
	-- tprint(moving_units)
end

function orbit_residual_take(moving_units, been_seen)
	update_dirs(cached_residual)
	for i, move in pairs(cached_residual) do
		table.insert(moving_units, move)
	end

	-- print("Submitting Residual Moves.")
	-- tprint(moving_units)
end

function orbit_orientation_take(moving_units, been_seen)
	update_dirs(cached_principal)
	-- print("Performed Orientational Updates.")
end

table.insert(mod_hook_functions.movement_take, orbit_principal_take)
table.insert(mod_hook_functions.movement_take, orbit_residual_take)
table.insert(mod_hook_functions.movement_take, orbit_orientation_take)


function derive_orbit_takes()
	local orbit_verb_graph = build_verb_graph("orbit")
	vprint("orbit_verb_graph", orbit_verb_graph)
	local deorbit_verb_graph = build_verb_graph("deorbit")
	vprint("deorbit_verb_graph", deorbit_verb_graph)
	local verb_graph = subtract_verb_graphs(orbit_verb_graph, deorbit_verb_graph)
	vprint("verb_graph", verb_graph)
	local process_order = graph_topological_sort(verb_graph)
	vprint("process_order", process_order)
	---@type table<uid_t, {x:integer, y:integer}>
	local new_pos_table = {}

	local principal_list = {}
	local residual_list = {}

	for i, lhs_uid in pairs(process_order) do
		print("processing object")
		vprint("lhs_uid", lhs_uid)
		local lhs_unit = mmf.newObject(lhs_uid)
		local lhs = {x=lhs_unit.values[XPOS], y=lhs_unit.values[YPOS]}
		lhs_then = compute_new_pos(lhs_uid, verb_graph[lhs_uid], verb_graph, new_pos_table)
		new_pos_table[lhs_uid] = lhs_then
		local pr, pv, rr, rv = decompose_position_change_into_steps(lhs, lhs_then, xor(isreverse(lhs_uid), is_majority_clockwise(verb_graph[lhs_uid])))
		
		if pr.dir >=0 and not isstill_or_locked(lhs_uid, lhs.x, lhs.y, pr.dir) then
			dir, ox, oy = reversecheck(lhs_uid, pr.dir, lhs.x, lhs.y) -- cancel out the default reverse behavior so we can implement it ourself
			table.insert(principal_list, {unitid = lhs_uid, reason = "orbit_principal", state = 0, moves = pr.moves, dir = dir, xpos = lhs.x, ypos = lhs.y})
		end
		if rr.dir >=0 and not isstill_or_locked(lhs_uid, lhs.x, lhs.y, rr.dir) then
			dir, ox, oy = reversecheck(lhs_uid, rr.dir, lhs.x, lhs.y) -- cancel out the default reverse behavior so we can implement it ourself
			table.insert(residual_list, {unitid = lhs_uid, reason = "orbit_residual", state = 0, moves = rr.moves, dir = dir, xpos = lhs.x, ypos = lhs.y})
		end
	end

	return principal_list, residual_list
end

---comment
---@param lhs_now {x:number, y:number}
---@param lhs_then {x:number, y:number}
---@return {dir:dir_t, moves:integer} principal_polar
---@return {x:number, y:number} principal_vec
---@return {dir:dir_t, moves:integer} residual_polar
---@return {x:number, y:number} residual_vec
function decompose_position_change_into_steps(lhs_now, lhs_then, is_reverse)
	-- vprint("lhs_now",lhs_now)
	-- vprint("lhs_then",lhs_then)
	local s_vec = {x=lhs_then.x-lhs_now.x, y=lhs_then.y-lhs_now.y}
	-- vprint("s_vec", s_vec)
	local p_dir = vec_to_dir(s_vec, not is_reverse) -- principal step direction
	-- vprint("p_dir", p_dir)
	local p_vec = dir_to_vec(p_dir) -- principal step unit vector
	-- vprint("p_vec", p_vec)
	local p_len = s_vec.x*p_vec.x + s_vec.y*p_vec.y -- step length needed for principal step
	-- vprint("p_len", p_len)
	local r_vec = {x=s_vec.x - p_len*p_vec.x, y=s_vec.y - p_len*p_vec.y} -- residual vector
	-- vprint("r_vec", r_vec)
	local r_dir = vec_to_dir(r_vec, not is_reverse)
	-- vprint("r_dir", r_dir)
	local r_len = math.abs(r_vec.x) + math.abs(r_vec.y)
	-- vprint("r_len", r_len)
	return {dir=p_dir, moves=p_len}, p_vec, {dir=r_dir, moves=r_len}, r_vec
end

---comment
---@param lhs_uid uid_t
---@param rhs_uids table<uid_t, integer>
---@param verb_graph graph_t
---@param new_pos_table {x:number, y:number, w:number}[]
---@return { x: integer, y: integer }
function compute_new_pos(lhs_uid, rhs_uids, verb_graph, new_pos_table)
	print("computing new position")
	-- vprint("lhs_uid", lhs_uid)
	-- vprint("rhs_uids", rhs_uids)
	-- vprint("verb_graph", verb_graph)
	-- vprint("new_pos_table", new_pos_table)

	local rhs_now, rhs_then = compute_rhs_positions(lhs_uid, rhs_uids, verb_graph, new_pos_table)

	-- vprint("rhs_now", rhs_now)
	-- vprint("rhs_then", rhs_then)

	local is_reverse = isreverse(lhs_uid)
	local lhs_unit = mmf.newObject(lhs_uid)
	local lhs_now = {x=lhs_unit.values[XPOS], y=lhs_unit.values[YPOS]}
	local lhs_now_invariant, lhs_now_imodulus = compute_invariant(lhs_now, rhs_now)
	local lhs_now_invariant_norm = normalize_invariant(lhs_now_invariant, lhs_now_imodulus, is_reverse)
	local lhs_now_progress, lhs_now_pmodulus = compute_progress(lhs_now, rhs_now, is_reverse)
	local target_step = compute_target_stepsize(rhs_then)

	lhs_now.invariant = lhs_now_invariant
	
	local function progress_key(pvalue)
		local progress = pvalue - lhs_now_progress

		if lhs_now_pmodulus > 0 then
			while progress < 0 do
				progress = progress + lhs_now_pmodulus
			end
			progress = math.fmod(progress, lhs_now_pmodulus)
		end
		return progress
	end
	lhs_now.progress = progress_key(lhs_now_progress)

	vprint("lhs_now", lhs_now)


	---@param lhs {x:integer, y:integer, invariant:number, progress:number}
	---@return number
	---@return table
	local function loss(lhs)
		i = {}
		-- prefer an actual step close in size to the target step size
		i.xy = math.abs(distance(lhs, lhs_now) - target_step)
		-- prefer a good approximation to the recovered invariant
		i.inv = math.abs((lhs.invariant/lhs_now_imodulus) - lhs_now_invariant_norm)
		-- prefer progress values that correspond to a step close to the target step size
		i.prog = math.abs((lhs.invariant * lhs.progress / lhs_now_pmodulus * math.pi*2) - target_step)

		if lhs.progress <= 0 then
			i.still = 1
		end
		-- prefer positions in which the recovered invariant value will be the same
		i.info = math.abs(normalize_invariant(lhs.invariant, lhs_now_imodulus, is_reverse) - lhs_now_invariant_norm)
		return combine_losses(i), i
	end

	---@type {x:integer, y:integer, invariant:number, progress:number, oob:boolean, loss:number}[]
	local all_lhs_list = {}
	local lower_x, upper_x, lower_y, upper_y = locked_search_bounds(lhs_uid)
	for x = lower_x, upper_x do -- we want to consider moves into out-of-bounds spaces, so we can be stopped by the edges
		for y = lower_y, upper_y do
			local lhs_then = {x=x,y=y}
			local lhs_then_invariant, lhs_then_imodulus = compute_invariant(lhs_then, rhs_then)
			lhs_then.invariant = lhs_then_invariant
			local lhs_then_progress, lhs_then_pmodulus = compute_progress(lhs_then, rhs_then, is_reverse)
			lhs_then.progress = progress_key(lhs_then_progress)
			lhs_then.oob = is_oob(lhs_then)
			lhs_then.loss, lhs_then.loss_info = loss(lhs_then)
			table.insert(all_lhs_list, lhs_then)
		end
	end

	local function loss_comp(a, b)
		return a.loss < b.loss
	end
	table.sort(all_lhs_list, loss_comp)

	vprint("all_lhs_list", all_lhs_list)

	return all_lhs_list[1]
end

function locked_search_bounds(uid)
	
	local unit = mmf.newObject(uid)
	local x, y = unit.values[XPOS], unit.values[YPOS]
	
	local lower_x = 1
	if isstill_or_locked(uid, x, y, DIRECTION_VALUES.Xn) then
		lower_x = x
	end
	local upper_x = roomsizex
	if isstill_or_locked(uid, x, y, DIRECTION_VALUES.Xp) then
		upper_x = x
	end
	local lower_y = 1
	if isstill_or_locked(uid, x, y, DIRECTION_VALUES.Yn) then
		lower_y = y
	end
	local upper_y = roomsizey
	if isstill_or_locked(uid, x, y, DIRECTION_VALUES.Yp) then
		lower_y = y
	end
	return lower_x, upper_x, lower_y, upper_y
end



---get the positions and weights of all rhs objects given the lhs object orbiting them
---@param lhs_uid uid_t
---@param rhs_uids table<uid_t, integer>
---@param verb_graph graph_t
---@return {x:number, y:number, w:number}[]
---@return {x:number, y:number, w:number}[]
function compute_rhs_positions(lhs_uid, rhs_uids, verb_graph, new_pos_table)
	local now, later = {}, {}

	local lhs = mmf.newObject(lhs_uid)
	local lx, ly = lhs.values[XPOS],lhs.values[YPOS]

	for rhs_uid, rhs_weight in pairs(rhs_uids) do
		rhs = mmf.newObject(rhs_uid)
		local rx, ry = rhs.values[XPOS],rhs.values[YPOS]
		local rw = rhs_weight --math.sqrt()
		
		-- print("computing influence point for pair:")
		-- vprint("lhs_uid", lhs_uid)
		-- vprint("rhs_uid", rhs_uid)

		local use_barycenter = false
		local lw = nil
		if verb_graph[rhs_uid] ~= nil then
			for maybe_lhs_uid, maybe_lhs_weight in pairs(verb_graph[rhs_uid]) do
				if maybe_lhs_uid == lhs_uid then
					-- print("they co-orbit!")
					use_barycenter = true
					lw = maybe_lhs_weight -- math.sqrt()
					if lw + rw == 0 then -- they're orbiting each other in the wrong order
						use_barycenter = false
					else
						break
					end
					-- vprint("lw", lw)
					-- vprint("rw", rw)
				end
			end
		end

		local x,y,w,nx,ny

		if use_barycenter then
			w = (lw + rw) / 2
			x = (lx*lw + rx*rw) / w / 2
			y = (ly*lw + ry*rw) / w / 2
			nx = x
			ny = y
		else
			w = rw
			x, y = rx, ry
			local N = new_pos_table[rhs_uid]
			if N ~= nil then
				nx, ny = N.x, N.y
			else
				nx, ny = x, y
			end
		end

		table.insert(now, {x=x, y=y, w=w})
		table.insert(later, {x=nx, y=ny, w=w})
	end
	return now, later
end

---compute the orbit invariant, which drives the on-rails behavior of the orbit
---in the case of two bodies this is just the radius
---@param lhs {x:number, y:number}
---@param rhs_list {x:number, y:number, w:number}[]
---@return number invariant The invariant value itself
---@return number invariant_modulus Invariant distance should be considered as a proportion of this value
function compute_invariant(lhs, rhs_list)
	-- print("computing invariant")
	-- vprint("lhs", lhs)
	-- vprint("rhs_list", rhs_list)
	local result = 0
	local modulus = 0
	for i, rhs in pairs(rhs_list) do
		result = result + distance(lhs, rhs) * rhs.w
		modulus = modulus + math.abs(rhs.w)
	end
	return result, modulus
end

function normalize_invariant(invariant, modulus, is_reverse)
	if is_reverse then
		return math.ceil(invariant/modulus - 0.5)
	else
		return math.floor(invariant/modulus + 0.5)
	end
end

---compute the orbit progress value, which drives the forward motion direction of the orbit
---also returns the progress modulus; values shoud be compared with regard to that modulus
---@param lhs {x:number, y:number}
---@param rhs_list {x:number, y:number, w:number}[]
---@param is_reverse boolean
---@return number progress The progress value itself
---@return number progress_modulus Progress should be considered modular around this value (unless zero)
function compute_progress(lhs, rhs_list, is_reverse)
	local total = 0
	local modulus = 0
	for i, rhs in pairs(rhs_list) do
		local dx = lhs.x - rhs.x
		local dy = lhs.y - rhs.y
		local ang = math.atan(dy, dx) + math.pi
		local arclen = ang / rhs.w
		local circum = 2*math.pi / rhs.w
		-- if the weight is 2x, we need 2x the distance to count for the same progress increment

		if not is_reverse then
			total = total + arclen 
			modulus = modulus + circum
		else
			total = total - arclen
			modulus = modulus - circum
		end
	end
	if math.abs(modulus) < math.pi * 2 then
		modulus =  math.pi * 2
	end
	return total, math.abs(modulus)
end

---compute the orbit progress value, which drives the forward motion direction of the orbit
---also returns the progress modulus; values shoud be compared with regard to that modulus
---@param rhs_list {x:number, y:number, w:number}[]
---@return number progress The progress value itself
function compute_target_stepsize(rhs_list)
	local max_w = 0
	for i, rhs in pairs(rhs_list) do
		if math.abs(rhs.w) > max_w then
			max_w =  math.abs(rhs.w)
		end
	end
	-- find the hypotenuse of a triangle with sides w and w/2
	return max_w --* math.sqrt(5/4)
end

---Determine if this adjacency is majority clockwise (for diagonal precedence purposes)
---@param neighbors table<uid_t, integer> neighbor table
---@return boolean
function is_majority_clockwise(neighbors)
	local sum = 0
	for n_uid, n_weight in pairs(neighbors) do
		sum = sum + n_weight
	end
	return sum > 0
end

---@param pos {x:integer, y:integer}
---@return boolean
function is_oob(pos)
	return pos.x < 1 or pos.y < 1 or pos.x > roomsizex or pos.y > roomsizey
end

---@param tab table
---@param pred fun(x:any):boolean
---@return integer
function count_predicate(tab, pred)
	local total = 0
	for i, v in pairs(tab) do
		if pred(v) then
			total = total + 1
		end
	end
	return total
end



---@param a {x:number, y:number}
---@param b {x:number, y:number}
---@return number
function distance(a, b)
	local dx = a.x-b.x
	local dy = a.y-b.y
	return math.sqrt(dx*dx+dy*dy)
end

function combine_losses(info)
	local magsq = 0
	for i, loss in pairs(info) do
		magsq = magsq + loss*loss
	end
	return math.sqrt(magsq)
end