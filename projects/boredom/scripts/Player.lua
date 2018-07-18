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
end

function Player:update(dt)
	self:platformerCollide("ground")

	if Input("move_left") then
		self.hspeed = -30
	end
	if Input("move_right") then
		self.hspeed = 30
	end
end
