-- require("Lua.utils")


cached_principle = {}
cached_residual = {}

function orbit_principle_take(moving_units, been_seen)
	cached_principle, cached_residual = derive_orbit_takes()

	update_dirs(cached_principle)
	for i, move in pairs(cached_principle) do
		table.insert(moving_units, move)
	end

	print("Submitting Principal Moves:")
	tprint(moving_units)
end

function orbit_residual_take(moving_units, been_seen)
	update_dirs(cached_residual)
	for i, move in pairs(cached_residual) do
		table.insert(moving_units, move)
	end

	print("Submitting Residual Moves:")
	tprint(moving_units)
end

function orbit_orientation_take(moving_units, been_seen)
	update_dirs(cached_principle)
	print("Performed Orientational Updates.")
end

table.insert(mod_hook_functions.movement_take, orbit_principle_take)
table.insert(mod_hook_functions.movement_take, orbit_residual_take)
table.insert(mod_hook_functions.movement_take, orbit_orientation_take)


function derive_orbit_takes()
	local verb_graph = build_verb_graph("orbit")
	vprint("verb_graph", verb_graph)
	local process_order = graph_topological_sort(verb_graph)
	vprint("process_order", process_order)
	---@type table<uid_t, {x:integer, y:integer}>
	local new_pos_table = {}

	local principle_list = {}
	local residual_list = {}

	for i, lhs_uid in pairs(process_order) do
		print("processing object")
		vprint("lhs_uid", lhs_uid)
		local lhs_unit = mmf.newObject(lhs_uid)
		local lhs = {x=lhs_unit.values[XPOS], y=lhs_unit.values[YPOS]}
		lhs_then = compute_new_pos(lhs_uid, verb_graph[lhs_uid], verb_graph, new_pos_table)
		new_pos_table[lhs_uid] = lhs_then
		local pr, pv, rr, rv = decompose_position_change_into_steps(lhs, lhs_then, isreverse(lhs_uid))
		
		if pr.dir >=0 and not isstill_or_locked(lhs_uid, lhs.x, lhs.y, pr.dir) then
			dir, ox, oy = reversecheck(lhs_uid, pr.dir, lhs.x, lhs.y)
			insert_move({unitid = lhs_uid, reason = "orbit_principle", state = 0, moves = pr.moves, dir = dir, xpos = lhs.x, ypos = lhs.y}, principle_list)
		end
		if rr.dir >=0 and not isstill_or_locked(lhs_uid, lhs.x, lhs.y, rr.dir) then
			dir, ox, oy = reversecheck(lhs_uid, rr.dir, lhs.x, lhs.y)
			insert_move({unitid = lhs_uid, reason = "orbit_residual", state = 0, moves = rr.moves, dir = dir, xpos = lhs.x, ypos = lhs.y}, residual_list)
		end
	end

	return principle_list, residual_list
end

---comment
---@param lhs_now {x:number, y:number}
---@param lhs_then {x:number, y:number}
---@return {dir:dir_t, moves:integer} principle_polar
---@return {x:number, y:number} principle_vec
---@return {dir:dir_t, moves:integer} residual_polar
---@return {x:number, y:number} residual_vec
function decompose_position_change_into_steps(lhs_now, lhs_then, is_reverse)
	vprint("lhs_now",lhs_now)
	vprint("lhs_then",lhs_then)
	local s_vec = {x=lhs_then.x-lhs_now.x, y=lhs_then.y-lhs_now.y}
	vprint("s_vec", s_vec)
	local p_dir = vec_to_dir(s_vec, not is_reverse) -- principle step direction
	vprint("p_dir", p_dir)
	local p_vec = dir_to_vec(p_dir) -- principle step unit vector
	vprint("p_vec", p_vec)
	local p_len = s_vec.x*p_vec.x + s_vec.y*p_vec.y -- step length needed for principle step
	vprint("p_len", p_len)
	local r_vec = {x=s_vec.x - p_len*p_vec.x, y=s_vec.y - p_len*p_vec.y} -- residual vector
	vprint("r_vec", r_vec)
	local r_dir = vec_to_dir(r_vec, not is_reverse)
	vprint("r_dir", r_dir)
	local r_len = math.abs(r_vec.x) + math.abs(r_vec.y)
	vprint("r_len", r_len)
	return {dir=p_dir, moves=p_len}, p_vec, {dir=r_dir, moves=r_len}, r_vec
end

---comment
---@param lhs_uid uid_t
---@param rhs_uids table<uid_t, integer>
---@param verb_graph graph_t
---@param new_pos_table {x:number, y:number, w:number}[]
---@return { x: integer, y: integer }
function compute_new_pos(lhs_uid, rhs_uids, verb_graph, new_pos_table)
	-- print("computing new position")
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

	local function progress_key(lhs_then)
		local progress = lhs_then.progress - lhs_now.progress
		while progress < 0 do
			progress = progress + lhs_then.pmodulus
		end
		progress = math.fmod(progress, lhs_then.pmodulus)
		return progress
	end

	local function progress_cmp(a, b)
		return progress_key(a) < progress_key(b)
	end

	-- vprint("candidate_lhs_list", candidate_lhs_list)

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

	vprint("candidate_lhs_list", candidate_lhs_list)
	vprint("steps", steps)
	vprint("selected_lhs", selected_lhs)

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
					-- vprint("lw", lw)
					-- vprint("rw", rw)
					break
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
	local result = 0
	local denom = 0
	for i, rhs in pairs(rhs_list) do
		local dx = lhs.x - rhs.x
		local dy = lhs.y - rhs.y
		local len = math.sqrt(dx*dx + dy*dy)
		result = result + len * rhs.w
		denom = denom + rhs.w
	end
	return (result / denom)
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
		modulus = modulus + rhs.w * 2*math.pi
	end
	return result, modulus
end

---
--- @param verb string
--- @return table<uid_t, table<uid_t, integer>>
function build_verb_graph(verb)
	result = {}

	local lhs_features = findfeature(nil,verb,nil)
	local lhs_uids = feature_list_to_uid_list(lhs_features)
	
	for i, lhs_uid in pairs(lhs_uids) do
		if not (isdead(lhs_uid) or issleep(lhs_uid) or isstill(lhs_uid)) then
			local lhs_name = get_uid_name(lhs_uid)
			local rules = collect_applicable_rules(lhs_uid, verb)
			local rhs_names = xthis(rules, lhs_name, "orbit")

			local rhs_uids = name_list_to_uid_list(rhs_names)

			for j, rhs_uid in pairs(rhs_uids) do
				if result[lhs_uid] == nil then
					result[lhs_uid] = {}
				end
				if result[lhs_uid][rhs_uid] == nil then
					result[lhs_uid][rhs_uid] = 0
				end
				result[lhs_uid][rhs_uid] = result[lhs_uid][rhs_uid] + 1
			end
			
		end
	end

	for lhs_uid, rhs_tab in pairs(result) do
		for rhs_uid, weight in pairs(rhs_tab) do
			result[lhs_uid][rhs_uid] = math.sqrt(weight)
		end
	end
	return result
end

function get_uid_name(uid)
	local unit = mmf.newObject(uid)
	local name = unit.strings[UNITNAME]
	if (unit.strings[UNITTYPE] == "text") then
		name = "text"
	end
	return name
end

---Collect rules that apply to 
---@param uid uid_t
---@return table
function collect_applicable_rules(uid, verb)
	local unit = mmf.newObject(uid)
	local name = get_uid_name(uid)
	local applicable_rules = {}

	if (featureindex[name] ~= nil) then					
		for i,rule_info in pairs(featureindex[name]) do
			local rule_main = rule_info[1]
			local rule_pred = rule_info[2]
			local rule_verb = rule_main[2]
			
			if (rule_verb == verb) and testcond(rule_pred, uid) then
				table.insert(applicable_rules, rule_info)
			end
		end
		
	end
	return applicable_rules
end
