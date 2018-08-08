BlankE.addState("PlayState");

--local player
main_camera = nil
local player = nil

function PlayState:enter(prev)
	Draw.setBackgroundColor('white')
	sc_level1 = Scene("level1")
	sc_level1.draw_order = {"ground","MovingBlock","SpikeBlock","spike","Player"}
	
	-- hitboxes
	sc_level1:addHitbox("ground")
	sc_level1:addHitbox("player_die")
	
	-- entities
	player = sc_level1:addEntity("player", Player, "bottom-center")[1]
	
	sc_level1:addEntity("moving_block", MovingBlock)
	local spikeblock_u = sc_level1:addEntity("spike_blockU", SpikeBlock)
	spikeblock_u:call("setMoveDir", "U")
	-- movingblock
	local moveblock_l = sc_level1:addEntity("moving_blockL", MovingBlock)
	moveblock_l:call("setMoveDir","L")
	local moveblock_r = sc_level1:addEntity("moving_blockR", MovingBlock)
	moveblock_r:call("setMoveDir","R")
	
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