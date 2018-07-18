BlankE.addEntity("Player")

function Player:init()
	self:addAnimation{
		name = "stand",
		image = "player_stand",
	}
	self:addPlatforming(0,0,self.sprite_width,self.sprite_height)
end

function Player:draw()
	self:drawSprite()
	self:debugCollision()
end