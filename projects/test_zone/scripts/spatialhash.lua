local CELL_SIZE = 60
local SpatialHash = class {
	init = function(self, size)
		self.elements = {}
		self.size = size or CELL_SIZE
	end,
	add = function(self, obj)
		local x = Math.ceil(obj.x / self.size) * self.size
		local y = Math.ceil(obj.y / self.size) * self.size
		local key = x .. ',' .. y
		
		if not self.element[key] then
			self.element[key] = {}
		end
		-- table.insert(
	end
}

Bunny = Entity("Bunny", {
	x = 0,
	y = 0,
	sprite = "bunny.bmp",
	is_spinning = true
})

System(All("sprite", "x", "y", "is_spinning", Not("dead")),{
	order = "post",
	added = function(ent)
		local spr = ent.sprite
		spr.x = ent.x
		spr.y = ent.y
		spr.align = "center"
		--spr.angle = Math.rad(45)
		--spr.scale = 3
	end,
	update = function(ent, dt)
		--ent.sprite.angle = ent.sprite.angle + Math.rad(10) * dt
		ent.sprite.scale = ent.sprite.scale + 5 * dt
	end
})

System(All("sprite"), {
	order = "pre",
	added = function(ent)
		ent.sprite = Image(ent.sprite)
		ent.sprite.debug = true
		ent.sprite:addDrawable()
	end,
	removed = function(ent)
		ent.sprite:destroy()
	end
})

State("spatialhash",{
	enter = function()
		Bunny{x = Game.width / 2, y = Game.height / 2}
	end,
	draw = function()
		Draw.color('red')
		Draw.line(0,Game.height/2,Game.width,Game.height/2)
		Draw.line(Game.width/2,0,Game.width/2,Game.height)
	end
})