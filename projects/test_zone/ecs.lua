-- Hitbox.debug = true

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
		
		for i = 1, 3 do -- 5000 do 
			HeartSpawner()
		end
		
		--[[
		Camera("player_ecs")--, {zoom=2})
		--Hitbox.debug = true
		
		Map.config{
			tile_hitbox = { megman = 'ground' }	
		}
		map = Map.load('platformer.map')
		]]
	end,
	update = function(dt)
		if Input.released('action') then 
-- 			destroy(map)
-- 			map = Map.load('platformer.map')
		end
		if Input.pressed('action') then 
			HeartSpawner()
		end
		-- print(System.stats())
		-- print(Cache.stats())
	end,
	draw = function()
		Draw{
			{'color','white'},
			{'line',Game.width/2,Game.height/2,mouse_x, mouse_y}
		}
	end
})

heart_ecs = {
	type='heart_ecs',
	image = { path='image2.png' },
	align = 'center',
	hitbox = true,
}

HeartSpawner = System{
	template=heart_ecs,
	add = function(obj)
		obj.pos = {
			x = Math.random(0, Game.width),
			y = Math.random(0, Game.height)
		}
		local scale = Math.random(0.5, 4.0)
		obj.scale = {
			x = scale,
			y = scale
		}
	end,
	update = function(obj, dt)
		obj.angle = Math.sinusoidal(-45,45,5)
		if Game.time > 1 then 
			obj.image.path = 'blue_robot.png'
		end
	end
}

local player_ecs = {
	animation = { 'blue_robot' },
	align='center',
	camera = { "player" },
	platforming = { gravity=10 },
	hitbox = true
}

--[[
System({
	hitbox = {
		collision = function(self, v)
			if v.normal.y < 0 then 
				self.vspeed = 0
			end
			if v.normal.y > 0 then 
				self.vspeed = -self.vspeed / 2
			end
		end
	},
	update = function(self, dt)		
		local hspd = 80
		local dx, dy = 0, 0
		
		-- horizontal
		if Input.pressed('right') then 
			dx = dx + hspd 
			self.scalex = 1
		end
		if Input.pressed('left') then 
			dx = dx - hspd 
			self.scalex = -1
		end
		self.hspeed = dx
		
		if Input.released('up') then 
			self.vspeed =  -250 
		end
	end
})]]