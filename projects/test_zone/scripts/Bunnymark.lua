local count = 0
local Bunny = Entity("bunny",{
	images = { "bunny.bmp" },
	--gravity = 10,
	--effect= { 'chroma shift' },
	spawn = function(self)
		self.x = Game.width/2
		self.x = Math.random(0,Game.width)
		self.y = Math.random(0,Game.height)
		self.hspeed = Math.random(40,150)*table.random{-1,1}
		count = count + 1
	end,
	update = function(self, dt)
		if self.x > Game.width then self.hspeed = -self.hspeed end
		if self.x < 0 then self.hspeed = -self.hspeed end 
		if self.y > Game.height then self.vspeed = -Math.abs(self.vspeed) end 
	end
})

local mark = 0 -- 1103

State("bunnymark",{
	enter = function()
		Input({
			action = { 'space' }
		})
		Timer.every(0.01, function()
			if mark == 0 then 
				Bunny()
			end
		end)
	end,
	update = function(dt)
		if Input.pressed("action") then
			for i = 0, 10 do 
				Bunny()
			end
		end
		if mark == 0 and count > 100 and love.timer.getFPS() <= Game.options.fps then 
			mark = count
		end
	end,
	draw = function()
		Draw{
			{'color','white'},
			{'fontSize',40},
			{'print',table.join({count,'FPS: '..love.timer.getFPS(),mark},'\n'), 30, 30}
		}
	end
})