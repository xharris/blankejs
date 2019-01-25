BlankE.addState("PlayState")

local player, asteroids
local tmr_spawn_roid

local eff

function PlayState:enter()
	PlayState.background_color = "black"
	
	player = Ship()
	asteroids = Group()
	
	tmr_spawn_roid = Timer():every(function()
		if Asteroid.instances:size() < 5 then
			asteroids:add(Asteroid())
		end
	end, 1):start()
end

function PlayState:update(dt)
	
end

function PlayState:draw()
	player:draw()
	asteroids:call("draw")
end
