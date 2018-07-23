BlankE.addEntity("Player")

function Player:init()
	self:addAnimation{
		name = "stand",
		image = "player_stand"
	}
	self:addAnimation{
		name = "walk",
		image = "player_walk",
		frames = {'1-2', 1},
		frame_size = {21, 33},
		speed = 0.2
	}
	self.sprite_xoffset = -self.sprite_width / 2
	self.sprite_yoffset = -self.sprite_height / 2 + 2
	
	self:addPlatforming(0,0,self.sprite_width,self.sprite_height)
	self.gravity = 20
	
	self.move_speed = 220
	self.max_jumps = 1
	
	self.jumps = self.max_jumps
end

function Player:update(dt)
	self:platformerCollide("ground", nil, nil,
		function()
			self.jumps = self.max_jumps
		end
	)

	-- left/right movement
	self.hspeed = 0
	if Input("move_left") then
		self.hspeed = -self.move_speed
	end
	if Input("move_right") then
		self.hspeed = self.move_speed
	end
	-- jumping
	if Input("jump") and self.jumps > 0 then
		self.vspeed = -650
		self.jumps = self.jumps - 1
	end
	
	-- animation
	if self.hspeed == 0 then
		self.sprite_index = "stand"	
		
	elseif self.hspeed > 0 then
		self.sprite_xscale = 1
		self.sprite_index = "walk"
		
	elseif self.hspeed < 0 then
		self.sprite_xscale = -1
		self.sprite_index = "walk"
		
	end
	
	if self.vspeed ~= 0 then
		self.sprite_index = "walk"
		self.sprite_speed = 0
		self.sprite_frame = 2
	else
		self.sprite_speed = 5
	end
end
