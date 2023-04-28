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
	vprint("lhs_uid", lhs_uid)
	vprint("rhs_uids", rhs_uids)
	-- vprint("verb_graph", verb_graph)
	-- vprint("new_pos_table", new_pos_table)

	local rhs_now, rhs_then = compute_rhs_positions(lhs_uid, rhs_uids, verb_graph, new_pos_table)

	vprint("rhs_now", rhs_now)
	vprint("rhs_then", rhs_then)

	local is_reverse = isreverse(lhs_uid)
	local lhs_unit = mmf.newObject(lhs_uid)
	local lhs_now = {x=lhs_unit.values[XPOS], y=lhs_unit.values[YPOS]}
	lhs_now.invariant = compute_invariant(lhs_now, rhs_now)
	lhs_now.progress, lhs_now.pmodulus = compute_progress(lhs_now, rhs_now, is_reverse)
	
	vprint("lhs_now", lhs_now)

	---@type {x:integer, y:integer}[]
	local candidate_lhs_list = {}
	for x = 1, roomsizex do
		for y = 1, roomsizey do
			local lhs_then = {x=x,y=y}
			lhs_then.invariant = compute_invariant(lhs_then, rhs_then)
			lhs_then.progress, lhs_then.pmodulus = compute_progress(lhs_then, rhs_then, is_reverse)
			if normalize_invariant(lhs_then.invariant) == normalize_invariant(lhs_now.invariant) then
				table.insert(candidate_lhs_list, lhs_then)
			end
		end
	end

	if #candidate_lhs_list <= 1 then 
		return lhs_now -- safety valve just in case
	end

	local function progress_key(lhs_then)
		local progress = lhs_then.progress - lhs_now.progress
		if lhs_then.pmodulus > 0 then
			while progress < 0 do
				progress = progress + lhs_then.pmodulus
			end
			progress = math.fmod(progress, lhs_then.pmodulus)
		end
		return progress
	end

	local function progress_cmp(a, b)
		return progress_key(a) < progress_key(b)
	end

	vprint("candidate_lhs_list", candidate_lhs_list)

	table.sort(candidate_lhs_list, progress_cmp)


	local steps = 1
	for rhs_uid, rhs_weight in pairs(verb_graph[lhs_uid]) do
		if steps < rhs_weight then
			steps = rhs_weight
		end
	end
	steps = steps + 1
	while steps > #candidate_lhs_list do
		steps = steps - #candidate_lhs_list
	end

	local selected_lhs = candidate_lhs_list[steps]

	-- vprint("candidate_lhs_list", candidate_lhs_list)
	-- vprint("steps", steps)
	-- vprint("selected_lhs", selected_lhs)

	return selected_lhs
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
---@return number
function compute_invariant(lhs, rhs_list)
	-- print("computing invariant")
	-- vprint("lhs", lhs)
	-- vprint("rhs_list", rhs_list)
	local numer = 0
	local denom = 0
	for i, rhs in pairs(rhs_list) do
		local dx = lhs.x - rhs.x
		local dy = lhs.y - rhs.y
		local len = math.sqrt(dx*dx + dy*dy)
		numer = numer + len * rhs.w
		denom = denom + rhs.w
	end
	if denom ~= 0 then
		return numer / denom
	else
		return numer
	end
	
	-- vprint("invariant", (result / denom) )
	-- return (numer / denom)
end

function normalize_invariant(invariant)
	return math.floor(invariant + 0.5)
end

---compute the orbit progress value, which drives the forward motion direction of the orbit
---also returns the progress modulus; values shoud be compared with regard to that modulus
---@param lhs {x:number, y:number}
---@param rhs_list {x:number, y:number, w:number}[]
---@param is_reverse boolean
---@return number, number
function compute_progress(lhs, rhs_list, is_reverse)
	local result = 0
	local modulus = 0
	for i, rhs in pairs(rhs_list) do
		local dx = lhs.x - rhs.x
		local dy = lhs.y - rhs.y
		local ang = math.atan(dy, dx) + math.pi
		if not is_reverse then
			result = result + rhs.w * ang
		else
			result = result - rhs.w * ang
		end
		modulus = modulus + math.abs(rhs.w) * 2*math.pi
	end
	return result, modulus
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