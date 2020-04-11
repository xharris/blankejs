local Obj
local type

State("hitbox",{
	enter = function()
		Timer.every(0.5,function()
			Obj({x=Math.random(0,Game.width),y=Math.random(0,Game.height)})
		end)
	end
})

Obj = Entity("HitboxObj",{
	reaction="bounce",
	hitbox=true,
	spawn=function(self)
		self.width = Math.random(10,30)
		self.height = Math.random(10,30)
		self.hspeed = Math.random(20,30) * table.random({-1,1})
		self.vspeed = Math.random(20,30) * table.random({-1,1})
	end,
	update = function(self, dt)
		if self.x > Game.width or self.x < 0 then self.hspeed = -self.hspeed end
		if self.y > Game.height or self.y < 0 then self.vspeed = -self.vspeed end
	end
})

Hitbox.debug = true