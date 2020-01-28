require 'xhh-array'

local map_size = {8,8}
GMap = class {
	size = {1,1},
	map = {},
	tiles = Array(),
	rooms = Array(),
	hitboxes = {}, -- { 'wall/doors_name': {#,#,#,#} }
	focus_walls = Array(),
	init = function(self)
		-- check if map is big enough
		self.size = copy(map_size)
		do
			local total_size = self.size[1] * self.size[2]
			local total_type_size = 0
			for room_type, info in pairs(GRoom.type_info) do
				info.w = info.w or 2
				info.h = info.h or 2
				total_type_size = total_type_size + info.w * info.h
			end
			total_type_size = total_type_size * 2
			local index = self.size[1] < self.size[2] and 1 or 2
			while total_type_size > total_size do
				self.size[index] = self.size[index] + 1
				total_size = self.size[1] * self.size[2]
				index = index == 1 and 2 or 1
			end
		end
		-- create rect grid
		for x = 1,self.size[1] do
			self.map[x] = {}
			for y = 1, self.size[2] do
				self.map[x][y] = GRoom{x=x,y=y,type='grass',map=self}
			end
		end
		-- create random area types
		for room_type, info in pairs(GRoom.type_info) do
			local taken = true
			-- find good location
			while taken do 
				taken = false
				local x, y = Math.random(1,self.size[1]), Math.random(1,self.size[2])
				for xcheck = x, x+info.w - 1 do
					for ycheck = y, y+info.h - 1 do
						if self.map[xcheck] and self.map[xcheck][ycheck] and self.map[xcheck][ycheck].type ~= "grass" then 
							taken = true
						end
					end
				end
				if not taken then 
					local room_info = GRoom.info(room_type)
					self:expand(x + room_info.w, y + room_info.w)
					self:addRoom(room_type, x, y)
				end
			end
		end
		self:updateWalls()
	end,
	expand = function(self, x, y)
		self.size = {x > self.size[1] and x or self.size[1], y > self.size[2] and y or self.size[2]}
		for ex = 1, self.size[1] do
			if not self.map[ex] then self.map[ex] = {} end
			for ey = 1, self.size[2] do
				if not self.map[ex][ey] then
					self.map[ex][ey] = GRoom{x=ex,y=ey,map=self}	
				end
			end
		end
	end,
	getGrassList = function(self)
		local ret_list = Array()
		
	end,
	addRoom = function(self, _type, x, y)
		local info = GRoom.info(_type)
		self:expand(x + info.w, y + info.h)
		local tiles = Array()
		for xtake = x, x+info.w - 1 do
			for ytake = y, y+info.h - 1 do
				local room = self.map[xtake][ytake] -- GRoom{x=xtake, y=ytake, type=_type, map=self}
				room.type = _type
				self.map[xtake][ytake] = room
				tiles:push(room)
			end
		end
		if _type ~= "grass" then	
			self.rooms:push(tiles)
		end
	end,
	updateWalls = function(self)
		-- update walls
		self.tiles:forEach(function(tile)
			local x, y, info = tile.x, tile.y, GRoom.info(tile.type)
			local checkWall = function(_x, _y, dir)
				local wall
				if not self.map[_x] or not self.map[_x][_y] or self.map[_x][_y].type ~= tile.type then 
					wall = GWall{dir=dir}
				end 
				if (not self.map[_x] or not self.map[_x][_y]) and wall then
					wall.to_outside = true
				end
				tile.walls:push(wall)
			end
			if not info.open then
				checkWall(x-1, y, 'left')
				checkWall(x+1, y, 'right')
				checkWall(x, y-1, 'up')
				checkWall(x, y+1, 'down')
			end
		end)
		-- create doors
		self.rooms:forEach(function(tiles)
			local info = GRoom.type_info[tiles[1].type]
			
			-- choose x random edges as a door
			if info.doors then
				for d = 1, info.doors do
					local new_tiles = tiles:copy()
					new_tiles:filter(function(t)
						print('TILE',t)
						return t.walls:some(function(w)
							print('> ',w,w.to_outside)
							return w.to_outside	== true		
						end)
					end)
					-- choose a random tile from the chunk
					local tile = table.random(new_tiles.table)
					-- choose a random wall from the tile
					local door_loc = table.random(tile.walls.table)
					if door_loc then 
						while door_loc.is_door or door_loc.to_outside do
							door_loc = table.random(tile.walls.table)
						end
						door_loc.is_door = true 
						-- remove wall from neighboring tile
						local nb = tile:getNeighbor(door_loc)
						if nb then
							nb.walls:filter(function(w) return w ~= door_loc end)	
						end
					end
				end
			end
		end)
	end,
	last_room = nil, -- for hitboxes
	getRoom = function(self, x, y)
		local size = GRoom.size
		local room_x, room_y = math.floor(x / GRoom.size[1]) + 1, math.floor(y / GRoom.size[2]) + 1
		-- set current room's boundaries (hitboxes)
		local room
		if self.map[room_x] and self.map[room_x][room_y] then room = self.map[room_x][room_y] end
		
		local pos_x, pos_y = (room_x-1) * size[1], (room_y-1) * size[2]
		local setHB = function(dir, dims)
			local name = dir
			if not self.hitboxes[name] then
				dims.tag = 'wall'
				self.hitboxes[name] = dims
			else
				table.update(self.hitboxes[name], dims)
			end
		end
		if room and self.last_room ~= room then
			self.last_room = room
			room.walls:forEach(function(w)
				print(w:getFullString())
				switch(w:getFullString(), {
					left = function() setHB('left',{
								x=pos_x - GRoom.tile_size, y=pos_y, 
								width=GRoom.tile_size, height=size[2] }) end,
					right = function() setHB('right',{
								x=pos_x + size[1], y=pos_y,
								width=GRoom.tile_size, height=size[2] }) end,
					up = function() setHB('top',{
								x=pos_x, y=pos_y - GRoom.tile_size,
								width=size[1], height=GRoom.tile_size }) end,
					down = function() setHB('down',{
								x=pos_x,y=pos_y + size[2],
								width=size[1], height=GRoom.tile_size }) end
				})
			end)
			-- add hitboxes
			for name, hb in pairs(self.hitboxes) do
				Hitbox.add(hb)
			end
		end
		return room_x, room_y
	end,
	getFocusPos = function(self, x, y)
		local size, outx, outy = GRoom.size, self:getRoom(x,y)
		return ((outx -1) * size[1]) + (size[1] / 2), 
			   ((outy -1) * size[2]) + (size[2] / 2)
	end,
	getFocusWalls = function(self, x, y)
		return self.focus_walls
	end,
	draw = function(self)
		for x = 1, self.size[1] do	
			for y = 1, self.size[2] do
				self.map[x][y]:drawInner()
			end
		end
		for x = 1, self.size[1] do	
			for y = 1, self.size[2] do
				self.map[x][y]:drawOuter()
			end
		end
	end
}

