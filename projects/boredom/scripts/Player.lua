BlankE.addClassType("Player", "Entity")

function Player:init()
	self:addAnimation{
		name = "stand",
		image = "player_stand",
	}
	self:addPlatforming(0,0,32,32)
	self.show_debug = true
end