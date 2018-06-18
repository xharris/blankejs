BlankE.addClassType("PlayState", "State");

function PlayState:enter(prev)
	Draw.setBackgroundColor('white')
	sc_level1 = Scene("scene0")
	bob = Player()
end

function PlayState:draw()
	sc_level1:draw()
end