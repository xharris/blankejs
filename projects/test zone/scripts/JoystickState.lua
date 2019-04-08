BlankE.addState("JoystickState")

local sc_level1

function JoystickState:enter()
	Scene.tile_hitboxes = {"ground"}
	sc_level1 = Scene("level1")
	local ent_mario = sc_level1:addEntity("spawn",Mario,"bottom left")
	--View("main"):follow(ent_mario)
end

function JoystickState:update(dt)
	
end

function JoystickState:draw()
	--View("main"):draw(function()
		sc_level1:draw()
	--end)
end
