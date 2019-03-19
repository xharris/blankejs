BlankE.addState("PlayState")

local player, sc_map, vw_main

Scene.tile_hitboxes = {"ground"}
Scene.hitboxes = {"ground"}
Scene.draw_order = {"ground","Player"}

function PlayState:enter()
	self.background_color = "white"

	sc_map = Scene("MapPlain")
	sc_map.draw_hitboxes = true
	vw_main = View("main")
		
	player = Player()
	player.x = game_width / 2
	player.y = game_height / 2
	player:setSpecialty(SPEC.EXPLOSIVE)
	
	-- setup scene
	sc_map:addEntity("player_spawn",player)
	
	-- setup camera
	vw_main:follow(player)
end

function PlayState:update(dt)

end

function PlayState:draw()
	vw_main:draw(function()
		sc_map:draw()
	end)
end
