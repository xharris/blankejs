Pathfinder = Class{
	map = {}, -- contains {'map_name'={x={y={'obstacle_id'=true/false}}}},...}
	init = function(self, name, cell_size)
		if not Pathfinder.map[name] then
			Pathfinder.map[name] = {}
		end
		self.name = name
		self.cell_size = cell_size or 20
		self.path = {}

		_addGameObject('pathing',self)
	end,

	_compressInfo = function(self, obj) 
		if obj.type == "entity" then
			--[[
			x = math.ceil(obj.x / self.cell_size), math.ceil(obj.y / self.cell_size)
			w = obj.sprite_width
			h = obj.sprite_height]]
		else
				   -- id
			return obj[1], 
				   -- x, y
				   math.ceil(obj[2] / self.cell_size) or 0, math.floor(obj[3] / self.cell_size) or 0,
				   -- w, h
				   math.floor(obj[4] / self.cell_size) or 0, math.ceil(obj[5] / self.cell_size) or 0
		end
	end,

	_expandInfo = function(self, obj)
		return obj[1], obj[2]*self.cell_size, obj[3]*self.cell_size, obj[4]*self.cell_size, obj[5]*self.cell_size
	end,

	-- obj : Entity OR {id, x, y, w, h}
	addObstacle = function(self, obj, cost)
		self:updateObstacle(obj, cost)
	end,

	_previous_pos = {}, -- {map_name={id={x,y,w,h}}}
	-- obj : Entity, obj with {id, x, y, w, h}
	updateObstacle = function(self, obj, cost)
		local id, x, y, w, h = self:_compressInfo(obj)
		local map = Pathfinder.map[self.name]


		-- remove previously filled cells
		if not Pathfinder._previous_pos[map] then Pathfinder._previous_pos[map] = {} else
			local last_pos = Pathfinder._previous_pos[map][id]
			if last_pos then
				if last_pos[1] == x and last_pos[2] == y and last_pos[3] == w and last_pos[4] == h then return end

				for gx = last_pos[1], last_pos[1] + last_pos[3], 1 do 
					for gy = last_pos[2], last_pos[2] + last_pos[4], 1 do
						if not (gx > x and gx < x + w and gy > y and gy < y + h) then -- is not inside current rect 
							map[gx][gy][id] = nil
						end
					end 
				end
			end
		end
		Pathfinder._previous_pos[map][id] = {x,y,w,h}

		for gx = x, x + w, 1 do 
			if not map[gx] then map[gx] = {} end
			for gy = y, y + h, 1 do
				if not map[gx][gy] then map[gx][gy] = {} end
				map[gx][gy][id] = cost or 1
			end 
		end
	end,
--[[
	getDStar = function(self, start_x, start_y, end_x, end_y)
		local path = {}
		local _
		_, start_x, start_y = self:_compressInfo{nil,start_x,start_y,0,0}
		_, end_x, end_y = self:_compressInfo{nil,end_x,end_y,0,0}

		function getNeighbors(point)

		end

		function setNextPointAndUpdateCost(src, target)

		end

		function setCost(point) end
		function getCost(point) end 
		function getMinCost(point) end

		local open_n, open = 0, {}
		function setOpen(point) end

		function isRaise(point)
			local cost 
			local neighbors = getNeighbors(currentPoint)

			if getCost(point) > getMinCost(point) then 
				for n, neighbor in ipairs(neighbors) do
					-- cost = neighbor cost & currentPoint cost
					if cost < getCost(point) then
						setNextPointAndUpdateCost(point, neighbor)
					end
				end
			end
			return getCost(point) > getMinCost(point)
		end

		local nextPoint = {}
		function expand(currentPoint)
			local isRaise = isRaise(currentPoint)
			local cost 
			local neighbors = getNeighbors(currentPoint)
			local neigh_id

			for n, neighbor in ipairs(neighbors) do
				if isRaise then
					if nextPoint[neighbor] == currentPoint then
						setNextPointAndUpdateCost(neighbor, currentPoint)
						setOpen(neighbor)
					else
						-- cost = neighbor cost & currentPoint cost 
						if cost < getCost(neighbor) then 
							-- setCost(currentPoint, minimumCost[currentPoint])
							setOpen(currentPoint)
						end
					end
				end
			end
		end

		while open_n > 0 do
			local point = open[1] -- sort first?
			expand(point)
		end
	end,]]

	getPath = function(self, start_x, start_y, end_x, end_y)
		local _
		_, start_x, start_y = self:_compressInfo{nil,start_x,start_y,0,0}
		_, end_x, end_y = self:_compressInfo{nil,end_x,end_y,0,0}

		local map = Pathfinder.map[self.name]
		local cells = {}
		local function h(x, y)
			return math.sqrt((x-end_x)^2 + (y-end_y)^2)
		end
		local function g(x, y)
			return math.sqrt((x-start_x)^2 + (y-start_y)^2)
		end
		
		local open, closed = {}, {}
		local open_n, closed_n = 0, 0
		function removeOpen(x,y) open[x..'.'..y] = nil end
		function removeClosed(x,y) open[x..'.'..y] = nil end
		function setOpen(x, y, key, val)
			if not open[x..'.'..y] then open_n = open_n + 1; open[x..'.'..y] = {x=x, y=y, g=g(x,y), h=h(x,y)} end 
			if closed[x..'.'..y] then closed_n = closed_n - 1; closed[x..'.'..y] = nil end

			local cell = open[x..'.'..y]
			if key then cell[key] = val end
			if key ~= 'f' then cell.f = cell.g + cell.h end
		end
		function setClosed(x, y, key, val)
			if not closed[x..'.'..y] then closed_n = closed_n + 1; closed[x..'.'..y] = {x=x, y=y, g=g(x,y), h=h(x,y)} end 
			if open[x..'.'..y] then open_n = open_n - 1; open[x..'.'..y] = nil end

			local cell = closed[x..'.'..y]
			if key then cell[key] = val end
			if key ~= 'f' then cell.f = cell.g + cell.h end
		end
		function getOpen(x, y) return open[x..'.'..y] end 
		function getClosed(x, y) return closed[x..'.'..y] end 
		function getLowestOpen()
			local lowest, low_cell
			for c, cell in pairs(open) do
				if not lowest then lowest = cell.f; low_cell = cell else
					if cell.f < lowest then cell.f = lowest; low_cell = cell end 
				end
			end
			return low_cell
		end
		function getCost(x ,y)
			if map[x] and map[x][y] then return map[x][y][x..'.'..y] or 0 end
			return 0
		end
		
		setOpen(start_x, start_y)
		local lowestOpen = getLowestOpen()
		local curr_x, curr_y = lowestOpen.x, lowestOpen.y
		local cost, neighbor
		local cells = {}
		cells[curr_x..'.'..curr_y]={parent=nil,x=curr_x,y=curr_y}

		while open_n > 0 and curr_x ~= end_x and curr_y ~= end_y do
			setClosed(curr_x, curr_y)
			for nx = curr_x - 1, curr_x + 1 do
				for ny = curr_y - 1, curr_y + 1 do
					cost = g(curr_x, curr_y) + getCost(nx, ny)
					neighbor = getOpen(nx, ny)
					if neighbor and cost < g(nx, ny) then
						removeOpen(nx, ny) -- new path is better
					end
					neighbor = getClosed(nx, ny)
					if neighbor and cost < g(nx, ny) then 
						removeClosed(nx, ny)
					end
					if not neighbor then
						setOpen(nx, ny, 'g', cost)
						cells[nx..'.'..ny] = {parent=curr_x..'.'..curr_y,x=nx,y=ny}
					end
				end
			end

			if open_n > 0 then
				lowestOpen = getLowestOpen()
				curr_x,	curr_y = lowestOpen.x, lowestOpen.y
			end
		end

		local ret_path = {}
		function addNode(cell)
			table.insert(ret_path, cell.x * self.cell_size)
			table.insert(ret_path, cell.y * self.cell_size)
			if cell.parent then addNode(cells[cell.parent]) end
		end
		addNode(cells[curr_x..'.'..curr_y])
		return ret_path
	end,

	_getPath = function(self, start_x, start_y, end_x, end_y)
		local path = {}
		local _
		_, start_x, start_y = self:_compressInfo{nil,start_x,start_y,0,0}
		_, end_x, end_y = self:_compressInfo{nil,end_x,end_y,0,0}
		
		local grid_vals = {}
		local map = Pathfinder.map[self.name]

		-- g : cost from current node to next node
		-- h : distance from node to goal
		function cost(x,y)
			local c = 0
			if map[x] and map[x][y] then for id, val in pairs(map[x][y]) do c = c + val end end
			return c 
		end
		function h(from_x, from_y) return
			--math.max(math.abs(from_x - end_x), math.abs(from_y - end_y))
			math.sqrt((from_x-end_x)^2 + (from_y-end_y)^2)
		end
		function g(to_x, to_y) return
			math.sqrt((to_x-start_x)^2 + (to_y-start_y)^2)
		end

		-- 1.  Initialize the open list
		-- 2.  Initialize the closed list
		local open, closed = {}, {}
		local open_n, closed_n = 0, 0
		function removeOpen(x,y) open[x..'.'..y] = nil end
		function removeClosed(x,y) open[x..'.'..y] = nil end
		function setOpen(x, y, key, val)
			if not open[x..'.'..y] then open_n = open_n + 1; open[x..'.'..y] = {x=x, y=y, g=0, h=h(x,y)} end 
			if closed[x..'.'..y] then closed_n = closed_n - 1; closed[x..'.'..y] = nil end

			local cell = open[x..'.'..y]
			if key then cell[key] = val end
			if key ~= 'f' then cell.f = cell.g + cell.h end
		end
		function setClosed(x, y, key, val)
			if not closed[x..'.'..y] then closed_n = closed_n + 1; closed[x..'.'..y] = {x=x, y=y, g=0, h=h(x,y)} end 
			if open[x..'.'..y] then open_n = open_n - 1; open[x..'.'..y] = nil end

			local cell = closed[x..'.'..y]
			if key then cell[key] = val end
			if key ~= 'f' then cell.f = cell.g + cell.h end
		end
		function getOpen(x, y) return open[x..'.'..y] end 
		function getClosed(x, y) return closed[x..'.'..y] end 
		local added = {}
		function addPoint(x, y)
			local new_x, new_y = x * self.cell_size, y * self.cell_size
			if not added[x..'.'..y] then
				table.insert(path, new_x)
				table.insert(path, new_y)
				added[x..'.'..y] = true
			end
		end

		function getSuccessors(qx, qy, qg)
			local successors = {}
			for x = qx - 1, qx + 1 do 
				for y = qy - 1, qy + 1 do 
					if not getClosed(x, y) then
						table.insert(successors, {x=x, y=y, g=g, f=g(x,y) + h(x,y)})
					end
				end
			end
			return successors
		end

		--[[ if path is already made, check if it needs to be updated
		if self.path then
			local cessors = getSuccessors(start_x, start_y)
			for s, cessor in ipairs()
		end]]

		local current_x, curent_y = 0,0
		--     put the starting node on the open list (you can leave its f at zero)
		setOpen(start_x, start_y, 'f', 0)
		-- 3.  while the open list is not empty
		local done = false
		local i = 0
		local max_i = (game_width * game_height) / self.cell_size
		while not done do
			i = i + 1
			done = (open_n < 1) or (i > max_i)
		--     a) find the node with the least f on the open list, call it "q"
			local q = nil
			for n, node in pairs(open) do
				if q == nil then
					q = node
				elseif node.f < q.f then
					q = node
				end 
			end
		--     c) generate q's 8 successors and set their 
		--        parents to q
			local temp_g, temp_h, temp_f
			local successors = getSuccessors(q.x, q.y, q.g)
			for s, cessor in ipairs(successors) do
	--     d) for each successor
	--         i) if successor is the goal, stop search
	--           successor.g = q.g + distance between 
	--                               successor and q
	--           successor.h = distance from goal to successor 
	--           successor.f = successor.g + successor.h
				if cessor.x == end_x and cessor.y == end_y then
					addPoint(cessor.x, cessor.y)
					done = true
				end 

	--         ii) if a node with the same position as 
	--             successor is in the OPEN list which has a 
	--            lower f than successor, skip this successor
				neighbor = getOpen(cessor.x,cessor.y)
				if neighbor and neighbor.f < cessor.f then 
					
				else 
	--         iii) if a node with the same position as 
	--             successor  is in the CLOSED list which has
	--             a lower f than successor, skip this successor
	--             otherwise, add  the node to the open list
					neighbor = getClosed(cessor.x,cessor.y)
					if not neighbor or (neighbor and neighbor.f >= cessor.f) then
						addPoint(q.x, q.y)
						setOpen(cessor.x, cessor.y, 'f', cessor.f)
					end 
				end
			end
		--     e) push q on the closed list
			setClosed(q.x, q.y)
		end
		-- table.insert(path, end_x * self.cell_size)
		-- table.insert(path, end_y * self.cell_size)
		return path
	end, 

	draw = function(self)
		local map = Pathfinder.map[self.name]
		local cell_size = self.cell_size
		local half_cell = self.cell_size /2
		Draw.setColor("red")
		for x, column in pairs(map) do
			for y, obstacles in pairs(column) do
				for id, _ in pairs(obstacles) do
					Draw.rect('line', x*cell_size - half_cell, y*cell_size - half_cell, cell_size, cell_size)
				end
			end
		end
	end
}

return Pathfinder