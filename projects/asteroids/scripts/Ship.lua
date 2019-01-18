BlankE.addEntity("Ship")

Input.set("left","left","a")
Input.set("right","right","d")
Input.set("thrust","up","w")
Input.set("brake","down","s")

function Ship:init()
	self.img_ship = Image("ship")
	self.img_ship.xoffset = self.img_ship.width/2
	self.img_ship.yoffset = self.img_ship.height/2
	
	self.img_thrust = Image("ship_thrust")
	self.img_thrust.xoffset = self.img_thrust.width/2
	self.img_thrust.yoffset = self.img_thrust.height/2
	
	self.x = game_width / 2
	self.y = game_height / 2
	
	self.turn_speed = 3
	self.move_angle = 0
	self.move_speed = 200
	self.accel = 4
end

function Ship:update(dt)
	-- TURNING
	self.friction = 0.005
	if Input("left").pressed then
		self.move_angle = self.move_angle - self.turn_speed
		self.friction = 0
	end
	
	if Input("right").pressed then
		self.move_angle = self.move_angle + self.turn_speed
		self.friction = 0
	end
	
	self.img_ship.angle = self.move_angle + 90
	self.img_thrust.angle = self.img_ship.angle
	
	-- MOVING FORWARD
	self.img_thrust.alpha = 0
	if Input("thrust").pressed then
		self:move(self.accel)
	end
	
	-- BRAKING
	if Input("brake").pressed then
		self:move(-self.accel)
	end
	
	-- WRAP SCREEN
	if self.x > game_width then self.x = 0 end
	if self.y > game_height then self.y = 0 end
	if self.x < 0 then self.x = game_width end
	if self.y < 0 then self.y = game_height end
end

function Ship:move(speed)
	self.hspeed = self.hspeed + direction_x(self.move_angle, speed)
	self.vspeed = self.vspeed + direction_y(self.move_angle, speed)
	
	if speed > 0 then self.img_thrust.alpha = 1 end
	
	-- LIMIT SPEED
	self.hspeed = clamp(self.hspeed, -self.move_speed, self.move_speed)
	self.vspeed = clamp(self.vspeed, -self.move_speed, self.move_speed)
end

function Ship:draw()
	self.img_ship:draw(self.x, self.y)
	self.img_thrust:draw(self.x, self.y)
	
	self:drawDebug()
end