Pathfinder = Class{
	map = {}, -- contains {'map_name'={x={y={'obstacle_id'=true/false}}}},...}
	init = function(self, name, cell_size)
		if not Pathfinder.map[name] then
			Pathfinder.map[name] = {}
		end
		self.name = name
		self.cell_size = cell_size or 5

		_addGameObject('pathing',self)
	end,

	_compressInfo = function(self, obj) 
		if obj.type == "entity" then
			--[[
			x = math.ceil(obj.x / self.cell_size), math.ceil(obj.y / self.cell_size)
			w = obj.sprite_width
			h = obj.sprite_height]]
		else
			return obj[1], --id
				   -- x, y
				   math.floor(obj[2] / self.cell_size) or 0, math.floor(obj[3] / self.cell_size) or 0,
				   -- w, h
				   math.floor(obj[4] / self.cell_size) or 0, math.floor(obj[5] / self.cell_size) or 0
		end
	end,

	_expandInfo = function(self, obj)
		return obj[1], obj[2]*self.cell_size, obj[3]*self.cell_size, obj[4]*self.cell_size, obj[5]*self.cell_size
	end,

	-- obj : Entity OR {id, x, y, w, h}
	addObstacle = function(self, obj)
		self:updateObstacle(obj)
	end,

	_previous_pos = {}, -- {map_name={id={x,y,w,h}}}
	-- obj : Entity, obj with {id, x, y, w, h}
	updateObstacle = function(self, obj)
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
				map[gx][gy][id] = true
			end 
		end
	end,

	getPath = function(self, start_x, start_y, end_x, end_y)

	end,

	draw = function(self)
		local map = Pathfinder.map[self.name]
		local cell_size = self.cell_size
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