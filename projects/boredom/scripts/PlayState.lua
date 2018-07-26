BlankE.addState("PlayState");

local player
main_camera = View()

function PlayState:enter(prev)
	Draw.setBackgroundColor('white')
	sc_level1 = Scene("scene0")
	sc_level1:addHitbox("ground")
	sc_level1:addHitbox("player_die")
	sc_level1.draw_hitboxes = true
	player = sc_level1:addEntity("player", Player, "bottom-center")[1]
	
	main_camera:follow(player)
end

function PlayState:update(dt)
	
end

function PlayState:draw()
	main_camera:draw(function()
		sc_level1:draw()
		player:draw()
	end)
end