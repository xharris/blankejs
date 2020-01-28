GRoom = class {
	type='grass',
	x=0, y=0,
	walls=nil,
	init = function(self, opts)
		self.walls = Set()
		table.update(self, opts)
		self.map.tiles:push(self)
	end,
	info = function(_type)
		return GRoom.type_info[_type]		
	end,
	drawInner = function(self)
		local size = GRoom.size
		local x, y, info = self.x * GRoom.size[1], self.y * GRoom.size[2], GRoom.info(self.type)
		x, y = x - GRoom.size[1], y - GRoom.size[2]
		Draw{
			{'lineWidth',2},
			{'color', info.color},
			{'rect', 'fill', x, y, GRoom.size[1], GRoom.size[2]},
			{'color','white'},
			{'rect', 'line', x, y, GRoom.size[1], GRoom.size[2]}
		}
	end,
	getNeighbor = function(self, side) -- side = string containing "left", "right", etc
		local offx, offy = 0, 0
		if string.contains(side, "left") then offx = -1 end
		if string.contains(side, "right") then offx = 1 end
		if string.contains(side, "up") then offy = -1 end
		if string.contains(side, "down") then offy = 1 end
		if self.map[self.x+offx] and self.map[self.x+offx][self.y+offy] then
			return self.map[self.x+offx][self.y+offy]
		end
	end,
	drawOuter = function(self)
		local size = GRoom.size
		local x, y, info = self.x * GRoom.size[1], self.y * GRoom.size[2], GRoom.info(self.type)
		x, y = x - GRoom.size[1], y - GRoom.size[2]
		self.walls:forEach(function(wall)
			Draw.color('black')
			if wall.to_outside then Draw.color('orange') end
			if not wall.is_door then
				if wall.dir == 'left' then Draw.line(x,y,x,y+GRoom.size[1]) end
				if wall.dir == 'right' then Draw.line(x+GRoom.size[1],y,x+GRoom.size[1],y+GRoom.size[2]) end
				if wall.dir == 'up' then Draw.line(x,y,x+GRoom.size[1],y) end
				if wall.dir == 'down' then Draw.line(x,y+GRoom.size[2],x+GRoom.size[1],y+GRoom.size[2]) end
			end
		end)
	end,
	__ = {
		eq = function(self, other)
			return self.x == other.x and self.y == other.y
		end,
		tostring = function(self)
			return self.x .. '.' .. self.y .. '.' .. self.type
		end
	}
}
local real_size = 10
GRoom.tile_size = 32
GRoom.size = {GRoom.tile_size*real_size,GRoom.tile_size*real_size}
GRoom.rooms = Array()
GRoom.type_info = {
	grass = {
		color='green'
	},
	cemetary = {
		color='gray',
		doors=1
	},
	forest = {
		color='indigo',
		w=6, h=6,
		open=true
	},
	house = {
		color='brown',
		w=4, h=4,
		doors=2
	}
}