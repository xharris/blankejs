Pathfinder = Class{
	map = {}, -- contains {'map_name'={x={y={'obstacle_id'=true/false}}}},...}
	init = function(self, name, cell_size)
		if not Pathfinder.map[name] then
			Pathfinder.map[name] = {}
		end
		self.name = name
		self.cell_size = cell_size or 20

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
				   math.floor(obj[2] / self.cell_size) or 0, math.floor(obj[3] / self.cell_size) or 0,
				   -- w, h
				   math.ceil(obj[4] / self.cell_size) or 0, math.ceil(obj[5] / self.cell_size) or 0
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

	getPath = function(self, start_x, start_y, end_x, end_y)
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
		function h(from_x, from_y) return math.sqrt((from_x-end_x)^2 + (from_y-end_y)^2) end

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

		local current_x, curent_y = 0,0

		--     put the starting node on the open list (you can leave its f at zero)
		setOpen(start_x, start_y, 'f', 0)
		-- 3.  while the open list is not empty
		local done = false
		while not done do
			done = (open_n < 1)
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
			local neighbor
			local temp_g, temp_h, temp_f
			for x = q.x - 1, q.x + 1 do 
				for y = q.y - 1, q.y + 1 do 
				
		--     d) for each successor
		--         i) if successor is the goal, stop search
		--           successor.g = q.g + distance between 
		--                               successor and q
		--           successor.h = distance from goal to successor 
		--           successor.f = successor.g + successor.h
					if x == end_x and y == end_y then
						addPoint(x, y)
						done = true
					end 
					temp_g = q.g + cost(x,y)
					temp_h = h(x,y)
					temp_f = temp_g + temp_h

		--         ii) if a node with the same position as 
		--             successor is in the OPEN list which has a 
		--            lower f than successor, skip this successor
					neighbor = getOpen(x,y)
					if neighbor and neighbor.f < temp_f then 
						
					else 
		--         iii) if a node with the same position as 
		--             successor  is in the CLOSED list which has
		--             a lower f than successor, skip this successor
		--             otherwise, add  the node to the open list
						neighbor = getClosed(x,y)
						if not neighbor or (neighbor and neighbor.f >= temp_f) then
							addPoint(q.x, q.y)
							setOpen(x, y, 'f', temp_f)
						end 
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
					Draw.rect('line', x*cell_size, y*cell_size, cell_size, cell_size)
				end
			end
		end
	end
}

return Pathfinder