BlankE.addClassType("PlayState", "State");

function PlayState:enter(prev)
	Draw.setBackgroundColor('white')
	bob = Player()
	sc_level1 = Scene("scene0")

end

function PlayState:draw()
	sc_level1:draw()
end