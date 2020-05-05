local count = 0
local abs = Math.abs
Bunny = Entity("bunny",{
	image = { path="bunny.bmp" },
	gravity = { v=10 },
	--effect= { 'chroma shift' },
	add = function(self)
		self.pos.x = Math.random(0, Game.width)--  Game.width/2
		self.pos.y = Math.random(0, Game.height)
		count = count + 1
	end,
	update = function(self, dt)
		if self.pos.x > Game.width then self.vel.x = -self.vel.x end
		if self.pos.x < 0 then self.vel.x = -self.vel.x end 
		if self.pos.y > Game.height then self.vel.y = -abs(self.vel.y) end 
	end
})

local mark = 0 -- 3429, 2930

State("bunnymark",{
	enter = function()
		Input.set({
			action = { 'space' }
		})
		Timer.every(.5, function()
			for i = 0, 10 do
				Bunny()
			end
		end)
		Window.vsync(0)
	end,
	update = function(dt)
		if Input.released("action") then
			for i = 0, 10 do 
				-- Bunny()
			end
		end
		if mark == 0 and count > 100 and love.timer.getFPS() <= Game.options.fps then 
			mark = count
			print('slowed down at '..mark)
		end
		-- print(World.stats('type'))
	end,
	draw = function()
		Draw{
			{'color','white'},
			{'fontSize',40},
			{'print',table.join({count,'FPS: '..love.timer.getFPS(),mark},'\n'), 30, 30}
		}
	end
})


local map
local heart_ecs

State('ecs',{
	enter = function()
		Input({
			right = { 'right', 'd' },
			left = { 'left', 'a' },
			up = { 'up', 'w' },
			down = { 'down', 's' },
			action = { 'space' }
		})
				
		for i = 1, 10 do -- 00 do 
			Heart()
		end
	end,
	update = function()
		if Input.pressed("action") then
			for i = 0, 10 do 
				Heart()
			end
		end
		print(World.stats())
	end,
	draw = function()
		Draw{
			{'color','gray'},
			{'line',Game.width/2,Game.height/2,mouse_x, mouse_y},
			{'fontSize',40},
			{'print',World.get_type_count('Heart'), 30, 30},
			{'color'}
		}
	end
})

Heart = Entity("Heart",{
	image = { path='image2.png' },
	animation = { name="walk" },
	align = { 'center' },
	hitbox = true,
	effect = { 'chroma shift' },
	vel = {},
	--gravity = { v=5 },
	add = function(obj)
		obj.pos = {
			x = Math.random(0, Game.width),
			y = Math.random(0, Game.height)
		}
		obj.vel.x = Math.random(40,80)*table.random{-1,1}
		local scale = Math.random(0.5, 4.0)
	end,
	update = function(obj, dt)
		--obj.angle = Math.sinusoidal(-45,45,5)
		if Game.time > 1 then 
			obj.image.path = 'blue_robot.png'
			obj.effect.names = {"static"}
		end
		if obj.pos.y > Game.height then 
			obj.vel.y = -Math.max(obj.vel.y,Game.height*1.2)
		end
		if obj.pos.x > Game.width or obj.pos.x < 0 then 
			obj.vel.x = -obj.vel.x
		end
		if obj.effect.static then 
			obj.effect.static.strength = { Math.lerp(0,20,obj.pos.x/Game.width), 0 }
		end
	end
})

Player = Entity("Player", {
	animation = { name='walk' },
	align={ 'center' },
	camera = { "player" },
	platforming = { gravity=10 },
	hitbox = true
})