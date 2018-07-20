BlankE.addEntity("Player")

function Player:init()
	self:addAnimation{
		name = "stand",
		image = "player_stand",
	}
	self.sprite_xoffset = -self.sprite_width / 2
	self.sprite_yoffset = -self.sprite_height / 2
	
	self:addPlatforming(0,0,self.sprite_width,self.sprite_height)
	self.gravity = 20
	
	self.move_speed = 180
	self.max_jumps = 1
	
	self.jumps = self.max_jumps
end

function Player:update(dt)
	self:platformerCollide("ground", nil, nil,
		function()
			self.jumps = self.max_jumps
		end
	)

	self.hspeed = 0
	if Input("move_left") then
		self.hspeed = -self.move_speed
		self.sprite_xscale = -1
	end
	if Input("move_right") then
		self.hspeed = self.move_speed
		self.sprite_xscale = 1
	end
	if Input("jump") and self.jumps > 0 then
		self.vspeed = -650
		self.jumps = self.jumps - 1
	end
end
