BlankE.addState("PlayState");

function PlayState:enter(prev)
	Draw.setBackgroundColor('white')
	sc_level1 = Scene("scene0")
	sc_level1:addHitbox("ground")
	main_player = sc_level1:addEntity("player", Player, "bottom-center")[1]
end

function PlayState:draw()
	sc_level1:draw()
end