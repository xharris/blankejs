State('platformer',{
	enter = function()
		Input({
			right = { 'right', 'd' },
			left = { 'left', 'a' },
			up = { 'up', 'w' }
		})
		
		Camera "player"
		Hitbox.debug = true
		
		Map.config{
			tile_hitbox = { megman = 'ground' }	
		}
		Map.load('platformer.map')
	end
})

Entity("player",{
	animations = { 'blue_robot' },
	animation = 'blue_robot',
	align = 'center',
	--camera = "player",
	hitbox = true,
	reaction = { ground = 'slide' },
	collision = function(self, v)
		if v.normal.y < 0 and not Hitbox.check(self,Math.sign(self.hspeed),0,'ground') then 
			self.vspeed = 0
		end
		if v.normal.y > 0 then 
			self.vspeed = -self.vspeed / 2
		end
	end,
	gravity = 10,
	update = function(self, dt)		
		local hspd = 80
		local dx, dy = 0, 0
		
		-- horizontal
		if Input.pressed('right') then dx = dx + hspd end
		if Input.pressed('left') then dx = dx - hspd end
		self.hspeed = dx
		
		if Input.pressed('up') then 
			self.vspeed = -300 
		end
	end
})