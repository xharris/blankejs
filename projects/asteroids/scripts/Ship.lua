Input.set("left","left","a")
Input.set("right","right","d")
Input.set("thrust","up","w")
Input.set("brake","down","s")
Input.set("shoot","space")

Input.set("kill","k")

BlankE.addEntity("Ship")

Ship.net_sync_vars = {'x','y','move_angle','thrust_alpha','pieces_alpha'}

function Ship:init()
	self.img_ship = Image("ship")
	self.img_ship.xoffset = self.img_ship.width/2
	self.img_ship.yoffset = self.img_ship.height/2
	
	self.img_thrust = Image("ship_thrust")
	self.img_thrust.xoffset = self.img_thrust.width/2
	self.img_thrust.yoffset = self.img_thrust.height/2
	
	self.snd_thrust = Audio("thrust")
	self.snd_thrust.looping = true
	
	self.snd_fire = Audio("fire")
	self.snd_fire.volume = 0.5
	
	self.snd_die = Audio("bangLarge")
	
	self.snd_beat1 = Audio("beat1")
	self.snd_beat2 = Audio("beat2")
	self.beat = 1
	
	self:addShape("main","circle",{0,0,self.img_ship.width/2})
		
	self.turn_speed = 3
	self.move_angle = -90
	self.move_speed = 300
	self.accel = 6
	self.thrust_alpha = 0
	self.dead = false
	self.pieces_alpha = 1
	
	self:spawn()
	
	self.bullets = Group()
	Net.addObject(self)
end

function Ship:spawn(x,y)
	self.x = ifndef(x, game_width / 2)
	self.y = ifndef(y, game_height / 2)
	
	self.can_shoot = true
	
	self:localOnly(function()
		self.tmr_beat = Timer(1)
		self.tmr_beat:after(function()
			if self.beat == 1 then
				self.snd_beat1:play()
				self.beat = 2
			elseif self.beat == 2 then
				self.snd_beat2:play()
				self.beat = 1
			end
			self.tmr_beat:start()
		end)	
		self.tmr_beat:start()
	end)

	-- death
	self.pieces = nil
	self.dead = false
	self.pieces_alpha = 1
end

function Ship:isNearRocks()
	Asteroid.instances:forEach(function(a, asteroid)
		if self:distance(asteroid) < asteroid.sprite_width + self.sprite_width then
			return true
		end
	end)
	return false
end

function Ship:update(dt)
	local snd_x = lerp(-1,1,self.x/game_width)
	Audio.setPosition(snd_x,0,0)
	
	self.img_ship.angle = self.move_angle + 90
	self.img_thrust.angle = self.img_ship.angle
	
	if self.dead then
		-- DEAD SHIP PIECES MOVEMENT
		self.pieces:forEach(function(p, piece)
			piece.hspeed = piece.hspeed * 0.99
			piece.vspeed = piece.vspeed * 0.99
			piece.x = piece.x + piece.hspeed * dt
			piece.y = piece.y + piece.vspeed * dt
		end)
	end
	
	if self.net_object then return end
	
	if not self.dead then
		self.onCollision["main"] = function(other, sep_vec)
			if not self.net_object and other.parent.classname == "Asteroid" then
				other.parent:hit(self.move_angle)
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


		-- MOVING FORWARD
		self.thrust_alpha = 0
		if Input("thrust").pressed then
			self:move(self.accel)
			self.snd_thrust:play()
		end

		-- BRAKING
		if Input("brake").pressed then
			self:move(-self.accel)
			self.snd_thrust:play()
		end
		if Input("brake").released or Input("thrust").released then
			self.snd_thrust:stop()
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
			new_bullet:netSync('x','y','direction')
			self.bullets:add(new_bullet)

			-- put shooting on cooldown
			self.can_shoot = false
			Timer(0.05):after(function() self.can_shoot = true end):start()
			
			self.snd_fire:play()
		end
	end
	
	if Input("kill").released then self:die() end
end

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
		
		self.snd_thrust:stop()
		self.snd_die:play()
		self:localOnly(function()
			self.tmr_beat:stop()
		end)
		
		self:removeShape("main")
		self.dead_time = game_time
		self.dead = true
		
		self:netSync("die")
		
		if not self.net_object then Signal.emit("player_die") end
	end
end

function Ship:move(speed)
	self.hspeed = self.hspeed + direction_x(self.move_angle, speed)
	self.vspeed = self.vspeed + direction_y(self.move_angle, speed)
	
	if speed > 0 then self.thrust_alpha = 1 end
	
	-- LIMIT SPEED
	self.hspeed = clamp(self.hspeed, -self.move_speed, self.move_speed)
	self.vspeed = clamp(self.vspeed, -self.move_speed, self.move_speed)
end

function Ship:draw()
	if self.dead then
		if self.pieces and self.pieces_alpha > 0 then
			self.pieces_alpha = self.pieces_alpha - 0.005
			self.pieces:set('alpha',self.pieces_alpha)
			self.pieces:call('draw')
		else
			self:destroy()
			if not self.net_object then Signal.emit("player_can_respawn") end
		end
	else
		self.img_thrust.alpha = self.thrust_alpha
		
		self.img_ship:draw(self.x, self.y)
		self.img_thrust:draw(self.x, self.y)
	end
	
	self.bullets:call("draw")
end