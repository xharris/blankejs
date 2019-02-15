BlankE.addState("PlayState")

local player
local asteroids = Group()
local tmr_spawn_roid
local can_respawn = false

local eff_death = Effect("static","chroma shift")
local main_view = View()
main_view.x = game_width / 2
main_view.y = game_height / 2

Input.set("respawn", "r")

function PlayState:enter()
	PlayState.background_color = "black"
	
	Net.on('ready',function()
		startGame()	
	end)
	
	Net.join()
end

function startGame()
	tmr_spawn_roid = Timer():every(function()
		if Net.is_leader and Asteroid.instances:size() < 2 then
			local new_asteroid = Asteroid()
			asteroids:add(new_asteroid)
		end
	end, 1):start()
	
	-- player death effect
	eff_death.chroma_shift.radius = 0
	eff_death.static.amount = {0,0}
	Signal.on("player_die",function()
		main_view:shake(10, 0)
	end)
	Signal.on("player_can_respawn",function()
		player = nil
		Timer(3):after(function()
			can_respawn = true
		end):start()
	end)
	
	player = Ship()
end

function PlayState:update(dt) 
	-- RESPAWN
	if not player and Input("respawn").released then 
		player = Ship()
		player.onSpawn = function()
			Net.addObject(player)
		end
		can_respawn = false
	end
end

function PlayState:draw()
	local function drawStuff()
		Net.draw("Bullet")
		if player then player:draw() end
		Net.draw("Ship")
		asteroids:call("draw")
		Net.draw("Asteroid")
	end
	
	main_view:draw(function()
		if player and player.dead then
			eff_death.chroma_shift.radius = main_view.shake_x
			eff_death.static.amount = {main_view.shake_x, 0}
				
			eff_death:draw(function()
				drawStuff()
			end)
		else
			drawStuff()
		end
	end)
end
