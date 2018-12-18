BlankE.addState("PlayState");

--local player
main_camera = nil
local player = nil

function PlayState:enter(prev)
	Draw.setBackgroundColor('white')
	
	-- hitboxes
	Scene.tile_hitboxes = {"ground"}
	Scene.hitboxes = {"ground", "player_die", "spike_blockStop", "boss1_stopper"}
	Scene.entities = {
		{"moving_block", MovingBlock},
		{"spike_block", SpikeBlock},
		{"door", DoorBlock},
		{"boss1", Boss1}
	}
	Scene.dont_draw = {"player"}
	Scene.draw_order = {"SpikeBlock","ground","MovingBlock","spike","DoorBlock"}
	
	--sc_level1 = Scene("level1")
	sc_boss1 = Scene("boss1")
	--sc_level1:chain(sc_boss1, "lvl_end", "lvl_start")
	player = sc_boss1:addEntity("player", Player, "bottom-center"):get(1)
	main_camera = View(player)
end

function PlayState:update(dt)
	if Input("restart").released and player.dead then
		State.switch(PlayState)	
	end
end

function PlayState:draw()
	if Input("action").released then
		main_camera:shake(0,10)	
	end
	main_camera.shake_speed = (mouse_x / game_width) * 50
	
	main_camera:draw(function()
		Scene.instances:call('draw')
		player:draw()
	end)
end