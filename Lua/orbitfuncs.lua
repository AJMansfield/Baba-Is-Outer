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

	return dx, dy
end