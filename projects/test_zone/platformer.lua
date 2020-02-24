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
	--gravity = 10,
	hitbox = true,
	collision = function(self, other, normal)
		if v.normal.y < 0 then 
			self.vspeed = 0
		end
		if v.normal.y > 0 then 
			self.vspeed = -self.vspeed / 2
		end
	end,
	update = function(self, dt)
		local hspd = 100
		self.hspeed = 0
		if Input.pressed('right') then self.hspeed = self.hspeed + hspd end
		if Input.pressed('left') then self.hspeed = self.hspeed - hspd end
		if Input.released('up') then self.vspeed = -300 end
	end
})