local SOCCER,BEACH,SPIKE,BOWLING,SMILE = 1,2,3,4,5
local VIEW_BALL_RANGE = false

Ball = Entity("Ball",{
	hitbox=true,
	reaction="cross",
	animations={ "ball" },
	align="center",
	spawn=function(self)
		self.anim_frame = Math.random(1,5)
			
		--				soccer, 	beach, 		spike, 		bowling, 	smile
		local scaling = {0.75,		1,			0.5,		1.5,		0.3 }
		local radius = 	{35,		50,			25,			75,			18 }
		local sound =	{'switch',	'car_door',	'crunch',	'cannon',	'drip'}
		
		self.scale = scaling[self.anim_frame]
		self.radius = radius[self.anim_frame]
		
		-- smile: bounce on floor and ceiling
		if self.anim_frame == SMILE then
			self.x = Game.width + self.radius
			self.y = Game.height/2
			self.hspeed = -100
			self.gravity = 20
			self.gravity_direction = table.random{90,270}
		end
		
		-- spike: move slowly vertically
		if self.anim_frame == SPIKE then 
			self.x = Math.random(self.width, Game.width - self.width)
			self.y = table.random{-self.radius, Game.height + self.radius}
			self.vspeed = 200 * -Math.sign(self.y)
		end
		
		-- soccer/beach/bowling: move left to right
		if self.anim_frame == SOCCER or self.anim_frame == BEACH or self.anim_frame == BOWLING then 
			self.x = -self.radius
		end
		
		-- soccer: move left to right at slight angle
		if self.anim_frame == SOCCER then 
			self.vspeed = 20 * table.random{-1,1}
			self.hspeed = 100
			self.y = Math.random(self.height, Game.height - self.height)
		end
		
		-- bowling: move SLOWLY left to right at slight angle
		if self.anim_frame == BOWLING then 
			self.vspeed = 20 * table.random{-1,1}
			self.hspeed = 40
			self.y = Math.random(self.height, Game.height - self.height)
		end
		
		-- beach
		if self.anim_frame == BEACH then 
			self.hspeed = 80
			self.percent = Math.random(0,100)
		end
		
		-- bowling
	end,
	is_colliding = function(self, other)
		return Math.distance(other.x, other.y, self.x, self.y) <= self.radius
	end,
	update = function(self, dt)
		-- smile/soccer/bowling: bounce off bottom of screen
		if (self.anim_frame == SMILE or self.anim_frame == SOCCER or self.anim_frame == BOWLING) 
		and (self.y + self.radius > Game.height or self.y - self.radius < 0) then 
			self.vspeed = -self.vspeed
		end
		-- ball: move in sine wave
		if self.anim_frame == BEACH then 
			self.y = Math.sinusoidal(self.height, Game.height - self.height, nil, self.percent/100)
		end
		-- NOT spike: die if off the screen
		if self.anim_frame ~= SPIKE and (self.x - self.width > Game.width or self.x + self.width < 0 or self.y - self.height > Game.height or self.y + self.height < 0) then
			self:destroy()
		end
		-- spike: die if off top/bottom of the screen
		if self.anim_frame == SPIKE and(self.y - self.height > Game.height or self.y + self.height < 0) then 
			self:destroy()
		end
	end,
	draw = function(self, d) 
		d()
		
		if VIEW_BALL_RANGE and player then
			Draw{
				{ 'color', 'green'},
				{ 'scale', 1/self.scale },
				{ 'print', Math.floor(Math.distance(player.x, player.y, self.x, self.y)) },
				{ 'color', 'green', 0.3 },
				{ 'circle', 'fill', 0, 0, self.radius }
			}
		end
	end
})