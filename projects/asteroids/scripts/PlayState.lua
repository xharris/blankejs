BlankE.addState("PlayState")

local player, asteroids
local tmr_spawn_roid

function PlayState:enter()
	PlayState.background_color = "black"
	
	player = Ship()
	asteroids = Group()
	
	tmr_spawn_roid = Timer():every(function()
		asteroids:add(Asteroid())
	end, 1):start()
end

function PlayState:update(dt)
	
end

function PlayState:draw()
	player:draw()
	asteroids:call("draw")
end
