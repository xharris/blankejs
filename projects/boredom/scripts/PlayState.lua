BlankE.addState("PlayState");

--local player
main_camera = nil
local player = nil

function PlayState:enter(prev)
	Draw.setBackgroundColor('white')
	sc_level1 = Scene("level1")
	sc_level1.draw_order = {"ground","MovingBlock","SpikeBlock","spike","Player"}
	
	-- hitboxes
	sc_level1:addHitbox("ground", "player_die", "spike_blockStop")
	
	-- entities
	player = sc_level1:addEntity("player", Player, "bottom-center")[1]
	
	-- blocks
	sc_level1:addEntity("moving_block", MovingBlock)
	sc_level1:addEntity("spike_block", SpikeBlock)
	sc_level1:addEntity("door", DoorBlock)
	
	main_camera = View()
	main_camera:follow(player)
end

function PlayState:update(dt)
	if Input("restart") and player.dead then
		State.switch(PlayState)	
	end
end

function PlayState:draw()
	main_camera:draw(function()
		sc_level1:draw()
	end)
end