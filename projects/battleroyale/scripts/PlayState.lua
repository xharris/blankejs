BlankE.addState("PlayState")

local player

function PlayState:enter()
	self.background_color = "white"
	
	player = Player()
	player.x = game_width / 2
	player.y = game_height / 2
	player:setSpecialty(SPEC.EXPLOSIVE)
end

function PlayState:update(dt)

end

function PlayState:draw()
	player:draw()
end
