BlankE.addClassType("PlayState", "State");

function PlayState:enter(prev)
	Draw.setBackgroundColor('white')
	sc_level1 = Scene("scene0")
	self
end

function PlayState:draw()
	sc_level1:draw()
end