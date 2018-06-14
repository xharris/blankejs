BlankE.addClassType("PlayState", "State");

function PlayState:enter(prev)
	Draw.setBackgroundColor('green')
	-- my_image = Image("ground")
end

function PlayState:draw()
	my_image:draw()
end