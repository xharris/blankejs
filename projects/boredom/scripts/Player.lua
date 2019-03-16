BlankE.addEntity("Player")

function Player:init()
	self:addAnimation{
		name = "stand",
		image = "player_stand"
	}
	self:addAnimation{name="walk", image="player_walk", frames={"1-2",1}, frame_size={21,33}, speed=0.2, offset={0,0}}
	self.sprite["walk"].yoffset = -1
	
	self:addAnimation{
		name = "dead",
		image = "player_dead"
	}
	self.sprite_index = "stand"
	
	self.sprite_xoffset = -self.sprite_width / 2
	self.sprite_yoffset = -self.sprite_height / 2
	
	self:addPlatforming(0,0,self.sprite_width-10,self.sprite_height+1)
	self.gravity = 20
	
	self.move_speed = 260
	self.max_jumps = 1
	self.dead = false
	self.jumps = self.max_jumps
	
	self.platform_hspeed = 0
end

function Player:draw()
	self:drawSprite()
end

function Player:update(dt)	
	self.hspeed = self.platform_hspeed
	
	self:platformerCollide{
		tag_contains="ground", 
		all=function(other, sep)
			if other.tag:contains("die") and not self.dead then
				self.dead = true
				--local transition_timer = Timer(1)
				--transition_timer:after(function()
					State.transition(DeathState, 'fade', 'black')	
				--end)
				--local death_tween = Tween(main_camera,{angle=30, scale_x=3, scale_y=3},2,'quad out')
				--death_tween:play()
				--transition_timer:start()
			end
		end,
		floor=function(other, sep)
			self.jumps = self.max_jumps
			
			self.platform_hspeed = 0
			if other.tag == "ground" and other.parent then
				if other.parent.hspeed ~= 0 then
					self.platform_hspeed = other.parent.hspeed
				end
				if other.parent.vspeed ~= 0 then
					self.y = other.parent.y - self.sprite_height
				end
			end
		end
	}

	-- left/right movement
	if not self.dead then
		if Input("move_left").pressed then
			self.hspeed = -self.move_speed + self.platform_hspeed
		end
		if Input("move_right").pressed then
			self.hspeed = self.move_speed + self.platform_hspeed
		end
		
		-- remove uncessecary platform speed
		if (Input("move_left").pressed or Input("move_right").pressed) and self:hadCollision("feet_box","ground") then
			self.platform_hspeed = 0
		end
		
		-- jumping
		if Input("jump").pressed and self.jumps > 0 then
			self.vspeed = -700
			self.jumps = self.jumps - 1
		end

		-- animation
		if self.hspeed == 0 then
			self.sprite_index = "stand"	

		elseif Input("move_right").pressed then
			self.sprite_xscale = 1
			self.sprite_index = "walk"

		elseif Input("move_left").pressed then
			self.sprite_xscale = -1
			self.sprite_index = "walk"

		else
			self.sprite_index = "stand"	
		end

		if self.vspeed ~= 0 or self.jumps == 0 then
			self.sprite_index = "walk"
			self.sprite_speed = 0
			self.sprite_frame = 2
		else
			self.sprite_speed = 5
		end
	else
		self.sprite_index = "dead"
	end
end
