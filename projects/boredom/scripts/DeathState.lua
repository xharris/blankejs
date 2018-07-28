BlankE.addState("DeathState")

function DeathState:enter()
	self.background_color = "black"
end

function DeathState:draw()
	if Input("restart") then
		State.switch(PlayState)	
	end
	
	Draw.setColor('white')
	Draw.text("hey there, lil fella", game_width / 2, game_height / 3)
end