local count = 0
local Bunny = Entity("bunny",{
	images = { "bunny.bmp" },
	gravity = 10,
	spawn = function(self)
		self.x = Game.width/2
		self.hspeed = Math.random(40,150)*table.random{-1,1}
		count = count + 1
	end,
	update = function(self, dt)
		if self.x > Game.width then self.hspeed = -self.hspeed end
		if self.x < 0 then self.hspeed = -self.hspeed end 
		if self.y > Game.height then self.vspeed = -self.vspeed end 
	end
})

State("bunny",{
	enter = function()
		Input({
			action = { 'space' }
		})
	end,
	update = function(dt)
		if Input.pressed("action") then
			for i = 0, 10 do 
				Bunny()
			end
		end
	end,
	draw = function()
		Draw{
			{'color','white'},
			{'fontSize',40},
			{'print',count, 30, 30}
		}
	end
})