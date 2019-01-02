BlankE.addEntity("Boss1")

local player

function Boss1:init()
	player = nil
	self.stage = 0
	
	self.initial_speed = 70
	self.incr_speed = 50
	self.max_speed = 80 -- don't fall off until boss is at max speed
	self.turn_dist = 100 -- distance between player/boss that causes turn around
	self.min_turns = 0 -- 3
	
	self.move_dir = -1
	self.turning = false
	self.turn_count = 0
	self.flying = false
	self.no_turning = false
	
	self.twn_turn = nil
	
	--[[ 
	0 - asleep
	1 - 4: NOT asleep (wow)
	]]
	
	self:addAnimation{name="sleep", image="boss1_sleep"}
	self:addAnimation{name="idle", image="boss1_idle"}
	self:addAnimation{name="walk1", image="boss1_walk1", frames={"1-2",1}, frame_size={36,41}, speed=0.4, offset={0,0}}
	
	self.x = self.scene_rect[1]
	self.y = self.scene_rect[2]
	self.gravity = 20
	self.sprite_xoffset = -16
	
	self:addShape("main","rectangle",{
			0, self.sprite_height+10,
			self.sprite_width, self.sprite_height-10
	})			
	self:setMainShape("main")
	self.sprite_index = "sleep"
	
	-- stage 0 
	self.z_canvas = Canvas(30, 30)
	self.z_canvas:drawTo(function()
		Draw.setColor("black")
		Draw.text("Z",0,0)
	end)
	self.y_canvas = Canvas(30, 30)
	self.y_canvas:drawTo(function()
		Draw.setColor("black")
		Draw.text("!",0,0)
	end)
	self.sleep_z = Repeater(self.z_canvas,{
		x = self.x + 5,
		y = self.y + 10,
		linear_accel_x = -10,
		max_linear_accel_x = 10,
		linear_accel_y = -10,
		end_color = {1,1,1,0}
	})
	
	self.run_blur = Repeater(self,{
		rate = 50,
		lifetime = .5,
		linear_accel_x = 20,
		color={1,0,0,1},
		end_color={1,1,1,0}
	})
	
	self.eff_static = Effect("static")
end

function Boss1:update(dt)	
	if not player then
		player = Player.instances[1]
	end
	
	self.onCollision["main"] = function(other, sep)
		if other.tag == "ground" then
			self:collisionStopY()
			-- landing after hitting spikes
			if self.flying then
				self.flying = false
				self.no_turning = false
				self:walkTowardsPlayer(self.move_dir)
			end
		end
		
		-- barriers that keep boss from falling too early
		if other.tag == "boss1_stopper" and self.turn_count < self.min_turns then
			self:collisionStopX()
			self:turn()
		end
		
		-- prevent boss from turning while falling onto spikes
		if other.tag == "boss1_stopper" and self.turn_count >= self.min_turns then
			self.no_turning = true
		end
		
		-- hit spikes and fly upwards
		if other.tag == "player_die" then
			self:hitSpikes()
		end
	end	
			
	-- start out sleeping. wake up when player comes near
	if self:distance(player) < 100 then
		self:wakeUp()
	end
	
	-- turn around while chasing player
	if self.stage > 1 and self:distance(player) > self.turn_dist then
		self:turn()
	end
end

function Boss1:draw()
	-- self.run_blur:draw()
				
	Draw.setColor("red")
	Draw.rect("line",self.x - self.turn_dist,0,2*self.turn_dist,game_height)
	Draw.reset("color")
	
	self.eff_static.amount = {(mouse_x / game_width) * 10,0}
	
	self.eff_static:draw(function()
		self:drawSprite()
	end)
end

function Boss1:wakeUp()
	if self.stage < 1 then
		self.stage = 1
		-- stand idly
		self.sprite_index = "idle"
		Timer(2):after(function()
			self.stage = self.stage + 1
			self:walkTowardsPlayer()	
		end):start()
	end
end

function Boss1:walkTowardsPlayer(direction_override, hspeed_override)
	self.turning = false
	-- which direction to go?
	if direction_override then
		self.move_dir = direction_override
	else
		if player.x < self.x then self.move_dir = -1
		else self.move_dir = 1 end
	end
	-- start moving
	self.hspeed = ifndef(hspeed_override, self.initial_speed + (self.incr_speed * self.turn_count)) * self.move_dir
	self.sprite_index = "walk1"--..(self.stage - 1)
	self.sprite_xscale = -self.move_dir
end

function Boss1:turn()
	Debug.log(self.no_turning,self.turning,self.flying)
	-- check if boss is facing away from player
	if not self.no_turning and not self.turning and not self.flying and ((self.move_dir < 0 and player.x > self.x) or (self.move_dir > 0 and player.x < self.x)) then
		self.sprite_xscale = self.move_dir
		self.turning = true
		self.twn_turn = Tween(self, {hspeed=0}, (self.stage / 10), nil, function()
			self.turn_count = self.turn_count + 1
			self:walkTowardsPlayer(-self.move_dir)	
		end):play()
	end
end

function Boss1:hitSpikes()
	if not self.flying then
		self.flying = true
		self.no_turning = false
		self.turn_count = 0
		
		if self.twn_turn then self.twn_turn:stop() end
		
		main_camera.shake_duration = 0.5
		main_camera:shake(0,4)
		
		-- increase starting numbers a little
		self.stage = self.stage + 1
		self.initial_speed = self.initial_speed + (self.stage * 10)
		
		-- uses magic formula for determining how far to fly
		self:walkTowardsPlayer(nil, math.max(self:distancePoint(player.x, self.y) * (1 + (self.stage / 10)) ), self.initial_speed)

		-- fly in the air
		self.vspeed = -(1200 + (self.stage * 20))
	end
end