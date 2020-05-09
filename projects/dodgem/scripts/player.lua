local hit_effect = {
	red = 0,
	shift_radius = 0,
	static_str = 0
}

Player = Entity("Player",{
	hitbox=true,
	reaction="cross",
	animations={ "robot_stand", "robot_walk", "robot_hit" },
	align="center",
	z=5,
	collision=function(self, i)
		if i.other.tag == "Ball" and i.other:is_colliding(self) then
			-- change frame
			self.is_hit = true
			-- visual effect
			hit_effect.red = 40
			hit_effect.shift_radius = 10
			hit_effect.static_str = 10
			
			if self.hit_effect_tween then 
				self.hit_effect_tween:destroy()
			end
			self.hit_effect_tween = Tween(1, hit_effect, { red=0, shift_radius=0, static_str=0 })
			-- audio effect
			Audio.play('hit')
		end
	end,
	update = function(self, dt)
		local d = 150
		self.hspeed = 0
		self.vspeed = 0
		-- basic movement
		Joystick.use(1)
		
		if Input.pressed('left') then self.hspeed = self.hspeed - d end
		if Input.pressed('right') then self.hspeed = self.hspeed + d end
		if Input.pressed('up') then self.vspeed = self.vspeed - d end
		if Input.pressed('down') then self.vspeed = self.vspeed + d end
		
		-- animation control
		if Input.pressed('left','right','up','down') then 
			self.animation = 'robot_walk'
		else 
			self.animation = 'robot_stand'
		end
		
		if self.is_hit then 
			self.animation = 'robot_hit'
			self.is_hit = false
		end
		
		-- mirror player image
		if Input.pressed('left') then 
			self.scalex = -1
		end
		if Input.pressed('right') then 
			self.scalex = 1
		end
		
		Joystick.use()
		
		Game.effect:set("chroma shift", "radius", hit_effect.shift_radius)
		Game.effect:set("static", "strength", {hit_effect.static_str, 0})
	end,
	draw = function(self, d)
		d()
		
		Draw{
			{ 'reset' }, -- prevent the square from drawing relative to the player
			{ 'color', 'red', hit_effect.red/100 },
			{ 'rect', 'fill', 0, 0, Game.width, Game.height }
		}
	end
})
