BlankE.addState("PlayState")

play_mode = 'online'			-- local / online
game_start_population = 1
best_penguin = nil

local main_penguin
local levels

-- Called every time when entering the state.
function PlayState:enter(previous)
	wall = nil
	main_penguin = nil
	last_lvl_end = {x=0, y=0}
	penguin_spawn = nil
	tile_snap = 32
		
	levels = Group()
	loadLevel("spawn")

	igloo_enter_x = penguin_spawn.x - 25
	destruct_ready_x = 0

	Draw.setBackgroundColor('white2')
	water_color = hsv2rgb({212,70,100})

	bg_sky = Image('background')
	bg_sky.color = {0,0,210}

	main_view = View()
	main_view.zoom_type = 'damped'
	main_view.zoom_speed = .05
end

local send_ready = false
function PlayState:update(dt)
	bg_sky.color = hsv2rgb({195,37,100})-- hsv2rgb({186,39,88})
	water_color = hsv2rgb({212,70,100})
	
	if Input("net_join") then
		Steam.init()
	end
	
	if Input('restart') then
		State.switch(playState)
	end

	-- enough players to start game
	if main_penguin.x > destruct_ready_x and not in_igloo_menu then
		if play_mode == 'online' and Net.getPopulation() >= game_start_population and not send_ready then
			send_ready = true
			Net.event("spawn_wall")
		end

		if play_mode == 'local' then
			startDestruction()
		end
	end

	-- player wants to enter igloo
	if main_penguin.x < penguin_spawn.x + 10 then
		Net.disconnect()

		-- zoom in on igloo
		main_view:follow()
		main_view:moveTo(penguin_spawn.x, penguin_spawn.y)

		-- transition to menu when zoomed in all the way
		if not wall then
			main_view:zoom(3, 3, function()
				State.transition(MenuState, "circle-out")
			end)
		end

	else
		if not Net.is_connected and play_mode == 'online' then
			Net.join()
		end
		
		main_view:zoom(1)
		main_view:follow(main_penguin)
	end
	
	-- load more levels!
	if best_penguin and best_penguin.x > last_lvl_end.x - (game_width/2) then

		local lvl_list = Asset.list('scene')
		local choice = ''
		repeat choice = table.random(lvl_list) until (#lvl_list == 1 or (choice ~= "spawn" and choice ~= "igloo"))
		
		if play_mode == 'local' then
			loadLevel(choice)
		elseif play_mode == 'online' then
			Net.sendPersistent({
				type="netevent",
				event="load_level",
				info=choice
			})
		end
	end
end

function PlayState:draw()
	-- draw water
	Draw.setColor(water_color)
	Draw.rect('fill',0,0,game_width,game_height)
	
	-- draw sky
	Draw.reset('color')
	bg_sky:tileX()

	-- draw objects
	main_view:draw(function()
		if wall then wall:draw() end
		FragImage.drawAll()

		Net.draw('DestructionWall')

		levels:call('draw','back')
		Net.draw('Penguin')
		if main_penguin then main_penguin:draw() end 
		levels:call('draw','front')
	end)
	
	local ready = ''
	if main_penguin.x > destruct_ready_x then ready = '\nREADY!' end
	Draw.setColor('black')
	Draw.text(tostring(Net.getPopulation())..' / '..tostring(game_start_population)..ready, game_width/2, 50)
end	

function loadLevel(name)
	local lvl_scene = Scene(name)
	lvl_scene.name_ref = name..levels:size()
	
	-- chain to the last scene
	if name ~= "spawn" then
		levels[-1]:chain(lvl_scene, "lvl_end", "lvl_start")
	end
			
	-- spawn: get 'ready to play' and 'spawn' spot
	if name == 'spawn' and not main_penguin then
		main_penguin = Penguin(true)
		lvl_scene:addEntity("spawn", main_penguin, "top left")
		penguin_spawn = {x=main_penguin.x-10, y=main_penguin.y}
		main_penguin:netSync()
		
		local destruct_tile = lvl_scene:getTiles("back", "ground_crack")[1]
		if descruct_tile then
			destruct_ready_x = destruct_tile.x
		end
	end
	
	last_lvl_end = {
		x=lvl_scene.offset_x,
		y=lvl_scene.offset_y
	}
	
	levels:add(lvl_scene)
end

function startDestruction()
	if not wall then
		--wall = DestructionWall()
		--wall.x = -32
	end
end

Net.on('ready', function()
	Net.addObject(main_penguin)
end)

local last_total_population = 0
local pop_refresh_timer = Timer(10)
Net.on('event', function(data)
	if data.event == "spawn_wall" then
		spawn_wall_count = spawn_wall_count + 1

		if spawn_wall_count >= Net.getPopulation() then
			startDestruction()
		end
	end
		
	if data.event == "load_level" then
		loadLevel(data.info)
	end
		
	if data.event == "client.connect" then
		pop_refresh_timer:reset()
		pop_refresh_timer:start()
			
	end
end)