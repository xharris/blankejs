BlankE.addState("PlayState");

local player
local main_camera

function PlayState:enter(prev)
	Draw.setBackgroundColor('white')
	sc_level1 = Scene("scene0")
	sc_level1:addHitbox("ground")
	player = sc_level1:addEntity("player", Player, "bottom-center")[1]
	
	main_camera = View()
	
end

function PlayState:draw()	
	sc_level1:draw()
	player:draw()
end