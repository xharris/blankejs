BlankE.addEntity("Ball")

function Ball:init()
	-- add the image of a ball and center it
	self:addSprite{name="main",image="ball",align="center"}
	-- give the Ball some gravity
	self.gravity = 6
	-- add a hitbox
	self:addShape('main','circle')
end

function Ball:update(dt)
	-- if the ball gets too close to the screen edges, flip its horizontal speed to have it go in the opposite direction
	if self.x < 0 or self.x > game_width then
		self.hspeed = -self.hspeed
	end
	
	-- bounce when the Ball hits a Paddle
	self.onCollision['main'] = function(other)
		if other.parent.classname == "Paddle" then
			self:collisionBounce(1.01)
			-- this will cause the ball to move slightly left or right depending on where it hits the paddle
			self.hspeed = (self.x - other.parent.x) * 5
			self.vspeed = math.min(self.vspeed, -400)
			-- will be used later for keeping score
        	Signal.emit("ball_hit_paddle")
		end
	end
end