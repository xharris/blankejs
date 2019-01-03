BlankE.addState("DeathState")

function DeathState:enter()
	DeathState.background_color = "black"
end

function DeathState:draw()
	if Input("restart").released then
		State.switch(PlayState)	
	end
	
	Draw.setColor('white')
	Draw.text("hey there, lil fella", game_width / 2, game_height / 3)
end