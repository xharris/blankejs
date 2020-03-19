Camera "player" 

Image.animation('player_stand.png')
Image.animation('player_dead.png')
Image.animation('player_walk.png', { { rows=1, cols=2, duration=0.1 } })
	
Hitbox.debug = true
	
Entity("Player", {
	camera = 'player',
	animations = {'player_stand','player_walk','player_dead'},
	align = "center",
	gravity = 10,
	can_jump = true,
	hitbox = true,
	collision = function(self, v)
		if v.other.tag == 'death' then
			self:die()
		end
		if v.normal.y < 0 then
			self.can_jump = true
		end
		if v.normal.y ~= 0 then 
			self.vspeed = 0
		end
	end,
	die = function(self)
		if not self.dead then
			self.dead = true
			self.animation = "player_dead"
			self.hit_area = "player_dead"
			Hitbox.adjust(self, -5, -20, -10, -22)
			Tween(1, self, { hspeed=0 }, nil, function()
				State.restart('play')
			end)
		end
	end,
	update = function(self, dt)
		if not self.dead then
			-- left/right
			dx = 125
			self.hspeed = 0
			if Input.pressed('right') then
				self.hspeed = dx
				self.scalex = 1
			end
			if Input.pressed('left') then
				self.hspeed = -dx
				self.scalex = -1
			end
			if Input.pressed('right') or Input.pressed('left') then
				self.animation = 'player_walk'
			else
				self.animation = 'player_stand'
			end
			-- jumping
			if Input.pressed('jump') and self.can_jump then
				self.vspeed = -350
				self.can_jump = false
			end

			self.animList['player_walk'].speed = 1

			if self.vspeed ~= 0 or not self.can_jump then
				self.animation = 'player_walk'
				self.animList['player_walk'].speed = 0
				self.animList['player_walk'].frame_index = 2
			end
		end
	end
})