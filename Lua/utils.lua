
---@alias uid_t number Lua stores it in a number type, but it's really an MMF object ID.

---@enum dir_t
DIRECTION_VALUES = {
	undefined = -1,
	W = -1,

	right = 0,
	R = 0,
	Xp = 0,

	up = 1,
	U = 1,
	Yn = 1,

	left = 2,
	L = 2,
	Xn = 2,

	down = 3,
	D = 3,
	Yp = 3,

	random = 4,
	Z = 4,
}

UNIT_VEC = {
	[DIRECTION_VALUES.W] = {x=0,y=0},
	[DIRECTION_VALUES.Xp] = {x=1,y=0},
	[DIRECTION_VALUES.Xn] = {x=-1,y=0},
	[DIRECTION_VALUES.Yp] = {x=0,y=1},
	[DIRECTION_VALUES.Yn] = {x=0,y=-1},
}

---Convert direction value to a unit vector.
---@param dir dir_t
---@return {x:number, y:number}
function dir_to_vec(dir)
	if dir == DIRECTION_VALUES.random then
		dir = fixedrandom(0,3)
	end
	return UNIT_VEC[dir]
end

---Convert direction value to a unit vector.

---comment
---@param vec {x:number, y:number}
---@param prefer_clockwise? boolean Treat diagonals as the next direction clockwise if true (default), or counterclockwise if false.
---@return integer
function vec_to_dir(vec, prefer_clockwise)
	local x, y = vec.x, vec.y
	if x == 0 and y == 0 then
		return DIRECTION_VALUES.undefined
	end

	if prefer_clockwise == nil then
		prefer_clockwise = true
	end

	local ax = math.abs(x)
	local ay = math.abs(y)

	if ax == ay then -- we're directly on the boundary
		-- just rotate the coordinate space 45 degrees
		if prefer_clockwise then
			x, y = x - y, x + y -- BIY uses a left-handed coordinate system
		else
			x, y = x + y, -x + y
		end
		ax = math.abs(x)
		ay = math.abs(y)
	end

	if (ax <= ay) then
		if (y >= 0) then
			return DIRECTION_VALUES.Yp
		else
			return DIRECTION_VALUES.Yn
		end
	else
		if (x > 0) then
			return DIRECTION_VALUES.Xp
		else
			return DIRECTION_VALUES.Xn
		end
	end
end

---@alias reason_t string The name of the verb or property that created this move.

---@alias moving_units_entry
---| {unitid:uid_t, reason:reason_t, state:integer, moves:integer, dir:dir_t, xpos:integer, ypos:integer}

---update the pointing direction of each sprite according to the move directions specified in the parameter
---@param moving_units moving_units_entry[]
function update_dirs(moving_units)
	for i, move in pairs(moving_units) do
		updatedir(move.unitid, move.dir)
	end
end

---insert a move, deduplicating it with other moves in the same or the opposite direction
---@param move moving_units_entry
---@param moving_units moving_units_entry[]
function insert_move(move, moving_units)
	-- print("Inserting Move!")
	-- vprint("move", move)

	if move == nil or move.dir < 0 then
		-- print("skipping insert move")
		return
	end

	local done = false

	for i, this in pairs(moving_units) do
		if this.unitid == move.unitid and this.xpos == move.xpos and this.ypos == move.ypos and this.reason == move.reason then
			-- print("found match")
			if this.dir == move.dir then
				-- print("adding to existing move")
				this.moves = this.moves + move.moves
				done = true
				break
			elseif this.dir == reversedir(move.dir) then
				-- print("subtracting from existing move")
				this.moves = this.moves - move.moves
				if this.moves < 0 then
					-- print("flipping existing move")
					this.moves = - this.moves
					this.dir = reversedir(this.dir)
				end
				done = true
				break
			else
				-- print("orthogonal")
			end
		end
	end

	if done == false then
		-- print("inserting new move")
		table.insert(moving_units, move)
	end
end

---Filter a moving_units table for only moves with a particular reason
---@param input_moving_units moving_units_entry[] Input table to search through.
---@param reason string
---@param output_moving_units? moving_units_entry[] Optional output table; if not provided one will be created for you.
---@return moving_units_entry[]
function filter_moves_by_reason(input_moving_units, reason, output_moving_units)
	if output_moving_units == nil then
		output_moving_units = {}
	end
	for i, move in pairs(input_moving_units) do
		if move.reason == reason and move.dir >= 0 and move.moves > 0 then
			table.insert(output_moving_units, move)
		end
	end
	return output_moving_units
end


---Get a list of all the unit ids named by a given a list of features that match the feature conditions.
---@param feature_list {[1]:string}[] Feature list, e.g. as returned by `findfeature`.
---@param ignorebroken_? boolean Whether to ignore broken status when checking feature conditions, default false.
---@return uid_t[]
function feature_list_to_uid_list(feature_list, ignorebroken_)
	local result = {}
	for i, feature in pairs(feature_list) do
		for j, uid in pairs(findall(feature, ignorebroken_)) do
			table.insert(result, uid)
		end
	end
	return result
end

---Get a list of all the unit ids named by a given a list of names.
---@param name_list string[] Name list, e.g. as returned by `xthis`.
---@return uid_t[]
function name_list_to_uid_list(name_list)
	local result = {}
	for i, name in pairs(name_list) do
		for j, uid in pairs(findall({name})) do
			table.insert(result, uid)
		end
	end
	return result
end

---@alias V any value type
---@alias K any uniqueness key type

---Deduplicate an array so it contains only unique values.
---@param tab V[] Table to deduplicate values from.
---@param key_func_? fun(x:V):K Function to use to extract a comparison key; if f(a) == f(b) then b is considered a duplicate of a.
---@return V[]
function unique(tab, key_func_)
	if key_func_ == nil then
		key_func_ = function (x)
			return x
		end
	end

	local set_tab = {}
	for i, v in pairs(tab) do
		set_tab[key_func_(v)] = v
	end

	local result = {}
	for k, v in pairs(set_tab) do
		table.insert(result, v)
	end

	return result
end

---Print a variable's value with type info.
---@param name any variable name
---@param value any variable value
function vprint(name, value)
	formatting = name .. "= (" .. type(value) .. ") "
	if value == nil then
		print(formatting .. "nil")
	elseif type(value) == "table" then
		print(formatting)
		tprint(value, 1)
	elseif type(value) == 'boolean' then
		print(formatting .. tostring(value))
	else
		print(formatting .. value)
	end
end

---Recursively print a table's contents.
---@param tbl any table to print
---@param indent? integer how many spaces to prefix each line
function tprint (tbl, indent)
	if not indent then
		indent = 0
	end
	for k, v in pairs(tbl) do
		formatting = string.rep("  ", indent) .. k .. ": (" .. type(v) .. ") "
		if v == nil then
			print(formatting .. "nil")
		elseif type(v) == "table" then
			print(formatting)
			tprint(v, indent+1)
		elseif type(v) == 'boolean' then
			print(formatting .. tostring(v))      
		else
			print(formatting .. v)
		end
	end
end

---test if a unit is dead
---@param unitid uid_t
---@return boolean
function isdead(unitid)
	if (unitid ~= 1) and (unitid ~= 2) then
		local unit = mmf.newObject(unitid)
		return unit.flags[DEAD]
	elseif (unitid == 1) then
		-- name = "level"
		return true
	else
		-- name = "empty"
		return true
	end
end

---test if a unit is reversed
---@param unitid uid_t
---@return boolean
function isreverse(unitid)
	return reversecheck(unitid, 0) ~= 0
end

---@alias graph_t table<uid_t, table<uid_t, integer>>

---traverse a graph in depth-first order
---@param graph graph_t
---@return uid_t[]
function graph_traverse_dfs(graph)
	local result = {}
	local visited = {}
	for node, children in pairs(graph) do
		graph_traverse_dfs_from_node(graph, node, visited, result)
	end
	return result
end

---helper to `graph_traverse_dfs`
---@param graph graph_t
---@param node uid_t
---@param visited table<uid_t, boolean>
---@param result uid_t[]
function graph_traverse_dfs_from_node(graph, node, visited, result)
	if not visited[node] then
		table.insert(result, node)
		visited[node] = true
		children = graph[node]
		if children ~= nil then
			for child, weight in pairs(children) do
				graph_traverse_dfs_from_node(graph, child, visited, result)
			end
		end
	end
end

---produce a topologically-sorted list of nodes; leaves first, then parents, then roots
---@param graph graph_t
---@return uid_t[]
function graph_topological_sort(graph)
	local WHITE, GREY, BLACK = nil, 0, 1
	local state = {}
	local result = {}
	
	for node, children in pairs(graph) do
		if state[node] == WHITE then
			graph_topological_sort_from_node(graph, node, state, result)
		end
	end
	return result
end

---comment
---@param graph graph_t
---@param node uid_t
---@param state table<uid_t, integer>
---@param result uid_t[]
function graph_topological_sort_from_node(graph, node, state, result)
	local WHITE, GREY, BLACK = nil, 0, 1
	if graph[node] ~= nil then
		state[node] = GREY
		for child, weight in pairs(graph[node]) do
			if state[child] == WHITE then
				graph_topological_sort_from_node(graph, child, state, result)
			elseif state[child] == GREY then
				-- we have a cycle!
			end
		end
		state[node] = BLACK
		table.insert(result, node)
	end
end

---
--- @param verb string
--- @return table<uid_t, table<uid_t, integer>>
function build_verb_graph(verb)
	result = {}

	local lhs_features = findfeature(nil,verb,nil)
	if lhs_features == nil then
		return {}
	end
	local lhs_uids = feature_list_to_uid_list(lhs_features)
	
	for i, lhs_uid in pairs(lhs_uids) do
		if not (isdead(lhs_uid) or issleep(lhs_uid) or isstill(lhs_uid)) then
			local lhs_name = get_uid_name(lhs_uid)
			local rules = collect_applicable_rules(lhs_uid, verb)
			local rhs_names = xthis(rules, lhs_name, verb)

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

function subtract_verb_graphs(a, b)
	result = {}
	for u, vlist in pairs(a) do
		if result[u] == nil then
			result[u] = {}
		end
		for v, w in pairs(vlist) do
			if result[u][v] == nil then
				result[u][v] = 0
			end
			result[u][v] = result[u][v] + w
			if result[u][v] == 0 then
				result[u][v] = nil
			end
		end
		if result[u] == {} then
			result[u] = nil
		end
	end
	for u, vlist in pairs(b) do
		if result[u] == nil then
			result[u] = {}
		end
		for v, w in pairs(vlist) do
			if result[u][v] == nil then
				result[u][v] = 0
			end
			result[u][v] = result[u][v] - w
			if result[u][v] == 0 then
				result[u][v] = nil
			end
		end
		if result[u] == {} then
			result[u] = nil
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


--- Returns false if value is falsey (`nil` or `false`), returns true if value is truthy (everything else)
---@param v any
---@return boolean
function toboolean(v)
    return v ~= nil and v ~= false
end

--- Returns true if one value is falsey and the other is truthy, returns false otherwise
---@param a any
---@param b any
---@return boolean
function xor(a, b)
    return toboolean(a) ~= toboolean(b)
end