BlankE.addClassType("PlayState", "State");

function PlayState:enter(prev)
	Draw.setBackgroundColor('green')
	my_image = Image("ground")
	my_image.x = game_width/2 
	my_image.y = game_height/2
	Input.keys["
end

function PlayState:draw()
	my_image:draw()
	love.graphics.setBackgroundColor(0.5,0.5,0.5)
end