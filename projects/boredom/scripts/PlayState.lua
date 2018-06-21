BlankE.addClassType("PlayState", "State");

function PlayState:enter(prev)
	Draw.setBackgroundColor('white')
	sc_level1 = Scene("scene0")
	sc_level1:addHitbox("ground")
	
	test_player = Player()	
end

function PlayState:draw()
	sc_level1:draw()
	test_player:draw()
end