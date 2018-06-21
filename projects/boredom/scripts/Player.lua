BlankE.addClassType("Player", "Entity")

function Player:init()
	self:addAnimation{
		name = "stand",
		image = "player_stand",
	}
	self.show_debug = true
end