BlankE.addState("PlayState")

local player, asteroids
local tmr_spawn_roid

local eff_death = Effect("static","chroma shift")
local main_view = View()

function PlayState:enter()
	PlayState.background_color = "black"
	
	player = Ship()
	asteroids = Group()
	
	main_view.x = game_width / 2
	main_view.y = game_height / 2
	
	tmr_spawn_roid = Timer():every(function()
		if Asteroid.instances:size() < 5 then
			asteroids:add(Asteroid())
		end
	end, 1):start()
	
	-- player death effect
	eff_death.chroma_shift.radius = 0
	eff_death.static.amount = {0,0}
	Signal.on("player_die",function()
		main_view:shake(10, 0)
	end)
end

function PlayState:draw()
	main_view:draw(function()
		if player.dead then
			eff_death.chroma_shift.radius = main_view.shake_x
			eff_death.static.amount = {main_view.shake_x, 0}
				
			eff_death:draw(function()
				player:draw()
				asteroids:call("draw")
			end)
		else
			player:draw()
			asteroids:call("draw")
		end
	end)
end
