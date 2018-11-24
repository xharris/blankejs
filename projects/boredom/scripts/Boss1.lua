BlankE.addEntity("Boss1")

local player

function Boss1:init()
	self.stage = 0
	
	self.initial_speed = 200--70
	self.incr_speed = 5
	self.max_speed = 80 -- don't fall off until boss is at max speed
	self.turn_dist = 100 -- distance between player/boss that causes turn around
	self.move_dir = -1
	
	self.turning = 0
	--[[ 
	0 - asleep
	1 - 4: NOT asleep (wow)
	]]
	
	self:addAnimation{
		name="sleep",
		image="boss1_sleep"
	}
	self:addAnimation{
		name="idle",
		image="boss1_idle"
	}
	self:addAnimation{name="walk1", image="boss1_walk1", frames={"1-2",1}, frame_size={36,41}, speed=1, offset={0,0}}
	
	self.x = self.scene_rect[1]
	self.y = self.scene_rect[2]
	self.gravity = 20
	self.sprite_xoffset = -16
	
	self:addShape("main","rectangle",{
			self.sprite_width, self.sprite_height+10,
			self.sprite_width, self.sprite_height-10
	})			
	self:setMainShape("main")
	self.sprite_index = "sleep"
	
	self.main_timer = Timer(2)
	self.speed_timer = Timer(2)
	
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
	
	-- stage timer
	self.main_timer:after(function()
		if self.stage == 1 then
			self.stage = 2	
			self.speed_timer:start()
		end
	end)
	
	-- speed timer
	self.speed_timer:after(function()
		if not self.turning and math.abs(self.hspeed) < self.max_speed then
			self.hspeed = self.hspeed + (self.move_dir * self.incr_speed)	
		end
	end)
	
	self.deccel_twn = Tween(self, {hspeed = 0}, 1)
end

function Boss1:update(dt)
	self.run_blur.spawn_x = self.x 
	self.run_blur.spawn_y = self.y 
	
	player = Player.instances:get(1)
	
	self.onCollision["main"] = function(other, sep)
		if other.tag == "ground" then
			self:collisionStopY()
		end
	end
			
	-- start turn around
	if self.stage >= 2 and self.turning == 0 and (self.hspeed < 0 and player.x > self.x + self.turn_dist) or (self.hspeed > 0 and player.x < self.x - self.turn_dist) then
		self.turning = 1 * math.sign(self.hspeed)
		self.sprite_xscale = -self.sprite_xscale
	end
	
	if self.turning ~= 0 and not self.deccel_twn.running then
		-- turning around
		self.deccel_twn.onFinish = function()
			-- finish turning around
			Debug.log("done turning")
			self.turning = 0
			self.move_dir = -self.move_dir
			self.initial_speed = self.initial_speed + 10
			self.hspeed = self.initial_speed
		end
		self.deccel_twn:play()
	end
		
	if self.stage == 0 and player then
		if self:distance(player) < 45 then
			self.sprite_index = "idle"
			self.stage = 1
		end
	
	elseif self.stage == 1 and not self.main_timer.running then
		self.main_timer:start()
	end
end

function Boss1:draw()
	-- self.run_blur:draw()
	Draw.stack(function()
		Draw.setColor("red")
		Draw.rect("line",self.x - self.turn_dist,0,2*self.turn_dist,game_height)
	end)
	
	-- stage 0: draw Z's
	if self.stage == 0 then
		self.sleep_z:draw()
		
	elseif self.stage == 1 then
	-- stage 1: waking up
		self.sleep_z:draw()
		self.sleep_z:setTexture(self.y_canvas)
		self.sprite_index = "idle"
		
	elseif self.stage == 2 then
	-- stage 2: walking
		self.sprite_index = "walk1"
		self.sprite_speed = 0.4
		self.hspeed = -self.initial_speed
		
	elseif self.stage == 3 then
	-- stage 3: jogging
		self.sprite_speed = 0.8
	end
	
	self:drawSprite()
end