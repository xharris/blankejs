Input.set("left","left","a")
Input.set("right","right","d")
Input.set("thrust","up","w")
Input.set("brake","down","s")
Input.set("shoot","space")

BlankE.addEntity("Bullet")

function Bullet:init()
	self.speed = 800
	self:addShape("main","circle",{0,0,1})
	Timer(1.5):after(function() self:destroy() end):start()
end

function Bullet:update(dt)
	if self.x > game_width then self.x = 0 end
	if self.x < 0 then self.x = game_width end
	if self.y > game_height then self.y = 0 end
	if self.y < 0 then self.y = game_height end
end

function Bullet:draw()
	Draw.setColor("white")
	Draw.circle("fill",self.x,self.y,1)
end

BlankE.addEntity("Ship")

function Ship:init()
	self.img_ship = Image("ship")
	self.img_ship.xoffset = self.img_ship.width/2
	self.img_ship.yoffset = self.img_ship.height/2
	
	self.img_thrust = Image("ship_thrust")
	self.img_thrust.xoffset = self.img_thrust.width/2
	self.img_thrust.yoffset = self.img_thrust.height/2
	
	self:addShape("main","circle",{0,0,self.sprite_width/2})
	
	self.x = game_width / 2
	self.y = game_height / 2
	
	self.turn_speed = 3
	self.move_angle = -90
	self.move_speed = 200
	self.accel = 4
	self.can_shoot = true
	-- death
	self.pieces = nil
	self.dead = false
	self.pieces_alpha = 1
	
	self.bullets = Group()
end

function Ship:update(dt)
	if not self.dead then
		self.onCollision["main"] = function(other, sep_vec)
			if other.parent.classname == "Asteroid" then
				other.parent:hit()
				self:die()
			end
		end

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

		-- SHOOTING
		if self.can_shoot and Input("shoot").released then
			local new_bullet = Bullet()
			new_bullet.x = self.x
			new_bullet.y = self.y
			new_bullet.direction = self.img_ship.angle - 90
			self.bullets:add(new_bullet)

			-- put shooting on cooldown
			self.can_shoot = false
			Timer(0.05):after(function() self.can_shoot = true end):start()
		end
	
	else
		-- DEAD SHIP PIECES MOVEMENT
		self.pieces:forEach(function(p, piece)
			piece.hspeed = piece.hspeed * 0.99
			piece.vspeed = piece.vspeed * 0.99
			piece.x = piece.x + piece.hspeed * dt
			piece.y = piece.y + piece.vspeed * dt
		end)
	end
	
	if Input("kill").released then self:die() end
end
Input.set("kill","k")
function Ship:die()
	if not self.dead then
		self.pieces = self.img_ship:chop(3,3)
		local diff_spd = 100
		self.pieces:forEach(function(p, piece)
			piece.dead_time = game_time
			piece.x = piece.x + self.x 
			piece.y = piece.y + self.y
			piece.hspeed = self.hspeed + randRange(-diff_spd,diff_spd)
			piece.vspeed = self.vspeed + randRange(-diff_spd,diff_spd)
		end)
		self:removeShape("main")
		self.dead_time = game_time
		self.dead = true
		
		Signal.emit("player_die")
	end
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
	if self.dead then
		if self.pieces_alpha > 0 then
			self.pieces_alpha = self.pieces_alpha - 0.005
			self.pieces:set('alpha',self.pieces_alpha)
			self.pieces:call('draw')
		end
	else
		self.img_ship:draw(self.x, self.y)
		self.img_thrust:draw(self.x, self.y)
	end
	self.bullets:call("draw")
end