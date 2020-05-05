local hit_effect = {
	red = 0,
	shift_radius = 0,
	static_str = 0
}

Player = Entity("Player",{
	hitbox=true,
	reaction="cross",
	animations={ "bluerobot" },
	align="center",
	z=5,
	collision=function(self, i)
		if i.other.tag == "Ball" and i.other:is_colliding(self) then
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
		local d = 100
		self.hspeed = 0
		self.vspeed = 0
		-- basic movement
		Joystick.use(1)
		
		if Input.pressed('left') then self.hspeed = self.hspeed - d end
		if Input.pressed('right') then self.hspeed = self.hspeed + d end
		if Input.pressed('up') then self.vspeed = self.vspeed - d end
		if Input.pressed('down') then self.vspeed = self.vspeed + d end
		
		-- mirror player image
		if Input.pressed('left') then 
			self.scalex = -1
		end
		if Input.pressed('right') then 
			self.scalex = 1
		end
		
		Joystick.use()
		
		--Game.effect:set("chroma shift", "radius", hit_effect.shift_radius)
		--Game.effect:set("static", "strength", {hit_effect.static_str, 0})
	end,
	draw = function(d)
		d()
		
		Draw{
			--{ 'color', 'red', hit_effect.red/100 },
			--{ 'rect', 'fill', 0, 0, Game.width, Game.height }
		}
	end
})
