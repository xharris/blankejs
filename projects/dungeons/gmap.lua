require 'xhh-array'

local map_size = {20,20}
GMap = class {
	size = {1,1},
	map = {},
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
				self.map[x][y] = GRoom{x=x,y=y,type='grass'}
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
					self.map[ex][ey] = GRoom{x=ex,y=ey}
				end
			end
		end
	end,
	addRoom = function(self, _type, x, y)
		local info = GRoom.info(_type)
		self:expand(x + info.w, y + info.h)
		local tiles = Array()
		if _type ~= "grass" then
			
		end
		for xtake = x, x+info.w - 1 do
			for ytake = y, y+info.h - 1 do
				local room = GRoom{x=xtake, y=ytake, type=_type, map=self}
				self.map[xtake][ytake] = room
				tiles:push(room)
			end
		end
		GRoom.rooms:push(tiles)
	end,
	updateWalls = function(self)
		-- connect all grass tiles
		for x = 1, self.size[1] do
			for y = 1, self.size[2] do
				if self.map[x] and self.map[x][y].type == "grass" then
					local tile = self.map[x][y]
					local checkWall = function(_x, _y, dir) 
						if not self.map[_x] or not self.map[_x][_y] or self.map[_x][_y].type ~= "grass" then tile.walls:push(dir) end 
					end
					checkWall(x-1, y, 'left')
					checkWall(x+1, y, 'right')
					checkWall(x, y-1, 'up')
					checkWall(x, y+1, 'down')
				end
			end
		end
		-- create doors
		GRoom.rooms:forEach(function(tiles)
			local info = GRoom.type_info[tiles[1].type]
			
			-- choose x random edges as a door
			if info.doors then
				local temp_tiles = tiles:copy():filter(function(t) 
					--print_r(t.walls)
					return t.walls.length > 0 
				end)
				for d = 1, info.doors do
					-- choose a random tile from the chunk
					local new_door = table.random(temp_tiles.table)
					-- choose a random wall from the tile
					local door_loc = table.random(new_door.walls.table)
					temp_tiles:filter(function(t) return t.x ~= new_door.x and t.y ~= new_door.y end)
					new_door.walls:remove(door_loc)
				end
			end
		end)
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

GRoom = class {
	type='grass',
	x=0, y=0,
	walls={},
	map=nil,
	init = function(self, opts)
		self.walls = Set()
		table.update(self, opts)
	end,
	info = function(_type)
		return GRoom.type_info[_type]		
	end,
	drawInner = function(self)
		local x, y, info = self.x * GRoom.size[1], self.y * GRoom.size[2], GRoom.info(self.type)
		Draw{
			{'lineWidth',2},
			{'color', info.color},
			{'rect', 'fill', x, y, GRoom.size[1], GRoom.size[2]},
			{'color','white'},
			{'rect', 'line', x, y, GRoom.size[1], GRoom.size[2]}
		}
	end,
	drawOuter = function(self)
		local x, y, info = self.x * GRoom.size[1], self.y * GRoom.size[2], GRoom.info(self.type)
		self.walls:forEach(function(wall)
			Draw.color('black')
			if wall == 'left' then Draw.line(x,y,x,y+GRoom.size[1]) end
			if wall == 'right' then Draw.line(x+GRoom.size[1],y,x+GRoom.size[1],y+GRoom.size[2]) end
			if wall == 'up' then Draw.line(x,y,x+GRoom.size[1],y) end
			if wall == 'down' then Draw.line(x,y+GRoom.size[2],x+GRoom.size[1],y+GRoom.size[2]) end
		end)
	end
}
GRoom.size = {16,16}
GRoom.rooms = Array()
GRoom.type_info = {
	grass = {
		color='green'
	},
	cemetary = {
		color='gray',
	},
	forest = {
		color='indigo',
		w=6, h=6
	},
	house = {
		color='brown',
		w=4, h=4,
		doors=2
	}
}