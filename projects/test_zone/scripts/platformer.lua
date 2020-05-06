-- Hitbox.debug = true

local map
State('platformer',{
	enter = function()
		Input.set({
			right = { 'right', 'd', 'gp.dpright' },
			left = { 'left', 'a', 'gp.dpleft' },
			up = { 'up', 'w', 'gp.a' },
			down = { 'down', 's' },
			action = { 'space' }
		})
		
		Camera("player")--, {zoom=2})
		--Hitbox.debug = true
		
		Map.config{
			tile_hitbox = { megman = 'ground' }	
		}
		map = Map.load('platformer.map')
	end,
	update = function(dt)
		if Input.released('action') then 
			map:destroy()
			map = Map.load('platformer.map')
		end
	end,
	draw = function()
		Draw{
			{'color','white'},
			{'line',-100,0,100,0},
			{'line',0,-100,0,100}
		}
	end
})

Entity("heart", {
	images = { 'image2.png' },
	align = 'center',
	hitbox = true,
})

Entity("player",{
	animations = { 'blue_robot' },
	align = 'center',
	camera = "player",
	hitbox = true,
	gravity = 10,
	--effect = 'static',
	--debug = true,
	collision = function(self, v)
		if v.normal.y < 0 then 
			self.vspeed = 0
		end
		if v.normal.y > 0 then 
			self.vspeed = -self.vspeed / 2
		end
	end,
	update = function(self, dt)		
		local hspd = 80
		local dx, dy = 0, 0
		
		local leftx = Input("gp.leftx")
		
		-- horizontal
		if Input.pressed('right') then 
			dx = dx + hspd 
			self.scalex = 1
		end
		if Input.pressed('left') then 
			dx = dx - hspd 
			self.scalex = -1
		end
		if leftx then 
			local val = Math.abs(leftx.value) < 0.1 and 0 or leftx.value
			dx = dx + (hspd * val) 
			leftx.joystick:setVibration(Math.abs(val), Math.abs(val))
		end
		
		self.hspeed = dx
		
		if Input.released('up') then 
			self.vspeed =  -250 
		end
	end
})