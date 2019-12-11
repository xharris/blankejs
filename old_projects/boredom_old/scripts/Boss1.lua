BlankE.addEntity("Boss1")

local player

--[[
	extra_speed		increased every X seconds and added to hspeed
	max_speed		don't fall off until boss is at max speed
	turn_dist		distance between player/boss that causes turn around
	incr_speed		added to initial_speed and max_speed on every turn
]]
local STAGE_VALS = {
	-- stage 1
	{
		initial_speed = 70,
		max_speed = 90,
		extra_speed = 10,
		turn_dist = 80,
		incr_speed = 50,
		min_turns = 3,
		turn_friction = 0.5
	},
	-- stage 2
	{
		initial_speed = 120,
		max_speed = 180,
		extra_speed = 10,
		turn_dist = 100,
		incr_speed = 10,
		min_turns = 3,
		turn_friction = 0.5
	},	
	-- stage 3
	{
		initial_speed = 70,
		max_speed = 90,
		extra_speed = 20,
		turn_dist = 100,
		incr_speed = 10,
		min_turns = 3,
		turn_friction = 0.5
	}
}

function Boss1:init()
	player = nil
	self.stage = 0
	
	self.initial_speed = 0
	self.max_speed = 0
	self.extra_speed = 0
	self.turn_dist = 0
	self.incr_speed = 0
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
	
	self:addSprite{name="sleep", image="boss1_sleep"}
	self:addSprite{name="idle", image="boss1_idle"}
	self:addSprite{name="walk1", image="boss1_walk1", frames={"1-2",1}, frame_size={36,41}, speed=0.4, offset={0,0}}
	
	self.x = self.scene_rect[1]
	self.y = self.scene_rect[2]
	self.gravity = 20
	self.sprite_xoffset = -16
	
	self:addPlatforming(0, self.sprite_height+10, self.sprite_width, self.sprite_height-10)			
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
		lifetime = 2,
		linear_accel_x = 20,
		color={0,0,0,.5},
		end_color={1,1,1,0}
	})
	--[[
	self.run_blur.rate = 50
	self.eff_boss1 = Effect("static","bloom")
	]]
	-- add extra speed
	Timer():every(1, function()
		if self.stage > 1 and not self.turning then
			self.hspeed = self.hspeed + (math.sign(self.hspeed) * (self.charge_step + self.accel))
			self.accel = self.accel + self.ACCEL
		end
	end):start()
	self.scale = 60
	
	self.charge_step = 1		
	self.charge_speed = 1.25		* self.scale
	self.realise_dist = 80		-- 40
	self.REALISE_DIST = 80		
	self.ACCEL = .005			* self.scale
	self.accel = 0
end

function Boss1:update(dt)	
	--Debug.log(self.hspeed)
	if not player then
		player = Player.instances[1]
	end
	
	self:platformerCollide{
		tag="ground",
		floor=function(other, sep)
			if self.flying then
				self.flying = false
				self.no_turning = false
				
				self:updateStageVals()
				self:walkTowardsPlayer(self.move_dir)
			end
		end,
		all=function(other, sep)
			-- barriers that keep boss from falling too early
			if other.tag == "boss1_stopper" then
				if self.turn_count < self.min_turns and not self.flying then
					self:collisionStopX()
					self:turn()
				else
					self.no_turning = true
				end
			end
				
			-- hit spikes and fly upwards
			if other.tag == "player_die" then
				self:hitSpikes()
			end
		end
	}
			
	-- start out sleeping. wake up when player comes near
	if self:distance(player) < self.realise_dist then
		self:wakeUp()
	end
	
	-- turn around while chasing player
	if self.stage > 1 and self:distancePoint(player.x, self.y) > self.realise_dist then
		self:turn()
	end
	
	-- limit speed
	if math.abs(self.hspeed) > self.initial_speed + self.max_speed then
		--self.hspeed = math.sign(self.hspeed) * (self.initial_speed + self.max_speed)
	end
	
	if not self.turning and not self.flying and self.stage > 1 then
		self.hspeed = self.move_dir * (self.charge_speed * self.charge_step + self.accel)
	end
end

function Boss1:draw()
	self.run_blur.spawn_x = self.x
	self.run_blur.spawn_y = self.y
				
	Draw.setColor("red")
	Draw.rect("line",self.x - self.realise_dist,0,2*self.realise_dist,game_height)
	Draw.reset("color")
	
	--self.eff_boss1.static.amount = {8, 0}
	--self.eff_boss1.bloom.samples = 5
	--self.eff_boss1:draw(function()
		--self.run_blur:draw()
		self:drawSprite()
	--end)
end

function Boss1:updateStageVals()
	-- use next set of speed vars
	table.update(self, STAGE_VALS[self.stage])
end

function Boss1:wakeUp()
	if self.stage < 1 then
		self.stage = 1
		self:updateStageVals()
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
	-- increase staring/max speeds
	if self.turn_count > 0 and self.turn_count <= self.min_turns then
		self.max_speed = self.max_speed + self.incr_speed
	end
	
	-- start moving
	if hspeed_override then
		self.hspeed = math.abs(hspeed_override) * self.move_dir
	end
	self.sprite_index = "walk1"--..(self.stage - 1)
	self.sprite_xscale = -self.move_dir
end

function Boss1:turn()
	-- check if boss is facing away from player
	if not self.no_turning and not self.turning and not self.flying and ((self.move_dir < 0 and player.x > self.x) or (self.move_dir > 0 and player.x < self.x)) then
		self.sprite_xscale = self.move_dir
		self.turning = true
		self.twn_turn = Tween(self, {hspeed=0}, clamp(self.turn_count / self.min_turns, .75, 1) * self.turn_friction, nil, function()
			self.turn_count = self.turn_count + 1
			self.initial_speed = math.abs(self.max_speed)
			self.charge_step = self.charge_step + 1
			self:walkTowardsPlayer(-self.move_dir)
		end):play()
			
		self.realise_dist = self.realise_dist - 5
		if self.turn_count > self.min_turns then
			self.realise_dist = 200	
		end
	end
end

function Boss1:hitSpikes()
	if not self.flying then
		self.flying = true
		self.no_turning = false
		self.turn_count = 0
		
		if self.twn_turn then self.twn_turn:stop() end
		
		local main_camera = View("main")
		main_camera.shake_duration = 0.5
		main_camera:shake(0,4)
		
		self.stage = self.stage + 1
		
		-- uses magic formula for determining how far to fly
		local next_init_speed = self.hspeed
		if STAGE_VALS[self.stage+1] then next_init_speed = STAGE_VALS[self.stage+1].init_speed end
		self:walkTowardsPlayer(nil, 200)
		
		-- fly in the air
		self.vspeed = -(1200 + (self.stage * 20))
		Debug.log(self.vspeed)
		
		self.realise_dist = self.REALISE_DIST + (self.stage*15)
	end
end