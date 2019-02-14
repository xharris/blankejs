BlankE.addState("PlayState")

local player, asteroids
local tmr_spawn_roid

local eff_death = Effect("static","chroma shift")

function PlayState:enter()
	PlayState.background_color = "black"
	
	player = Ship()
	asteroids = Group()
	
	tmr_spawn_roid = Timer():every(function()
		if Asteroid.instances:size() < 5 then
			asteroids:add(Asteroid())
		end
	end, 1):start()
	
	-- player death effect
	eff_death.chroma_shift.radius = 0
	eff_death.static.amount = {0,0}
	Signal.on("player_die",function()
		Tween(eff_death, {
			chroma_shift={
				radius=2
			},
			static={
				amount={2,2}	
			}
		}):play()
	end)
end

function PlayState:update(dt)
	-- Debug.log(eff_death.chroma_shift.radius, eff_death.static.amount[1], eff_death.static.amount[2])
end

function PlayState:draw()
	if player.dead then
		eff_death:draw(function()
			player:draw()
			asteroids:call("draw")
		end)
	else
		player:draw()
		asteroids:call("draw")
	end
end
