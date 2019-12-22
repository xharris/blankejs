Camera "player" 

Image.animation('player_stand.png')
Image.animation('player_dead.png')
Image.animation('player_walk.png', { { rows=1, cols=2, duration=0.2 } })

Entity("Player", {
		camera = 'player',
		animations = {'player_stand','player_walk','player_dead'},
		align = "center",
		gravity = 10,
		can_jump = true,
		hitbox = true,
		hitArea = {
			left = -5,
			right = -10
		},
		collision = function(self, v)
			if v.other.tag == 'death' then
				self:die()
			end
			if v.normal.y < 0 then
				self.can_jump = true
				self.vspeed = 0
			end
			if v.normal.y > 0 then 
				self.vspeed = -self.vspeed/2
			end
		end,
		die = function(self)
			if not self.dead then
				self.dead = true
				self.hitArea = 'player_dead'
				Tween(2, self, { hspeed=0 })
				State.stop()
				State.start('play')
			end
		end,
		update = function(self, dt)
			if self.dead then	
				self.animation = "player_dead"
			else 
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
				if Input.pressed('jump') then -- and self.can_jump then
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