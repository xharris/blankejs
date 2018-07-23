BlankE.addState("PlayState")

play_mode = 'online'			-- local / online
game_start_population = 1
best_penguin = nil

local main_penguin

-- Called every time when entering the state.
function PlayState:enter(previous)
	wall = nil
	main_penguin = nil
	next_lvl_start = {0,0}
	last_lvl_end = {0,0}
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
		main_view:moveToPosition(penguin_spawn.x, penguin_spawn.y)

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
	if best_penguin and best_penguin.x > last_lvl_end[1] - (game_width/2) then
		--
		local lvl_list = Asset.list('scene','level')
		local choice = ''
		repeat choice = table.random(lvl_list) until (choice ~= "spawn")
		
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

local spawn_wall_count = 0
function PlayState:draw()
	-- draw water
	Draw.setColor(water_color)
	Draw.rect('fill',0,0,game_width,game_height)
	
	-- draw sky
	Draw.resetColor()
	bg_sky:tileX()

	-- draw objects
	main_view:draw(function()
		if wall then wall:draw() end
		FragImage.drawAll()

		Net.draw('DestructionWall')

		levels:call('draw','layer1')
		Net.draw('Penguin')
		if main_penguin then main_penguin:draw() end 
		levels:call('draw','layer0')
		
		Draw.setColor("red")
		Draw.setLineWidth(3)
		Draw.line(penguin_spawn.x, 0, penguin_spawn.x, game_height)	
	end)
	
	local ready = ''
	if main_penguin.x > destruct_ready_x then ready = '\nREADY!' end
	Draw.setColor('black')
	Draw.text(tostring(Net.getPopulation())..' / '..tostring(game_start_population)..ready, game_width/2, 50)
	
	if Net.is_leader then
		Draw.setColor('yellow')
		Draw.circle('fill',20,20,50)
	end
end	

function loadLevel(name)
	local lvl_scene = Scene('level/'..name)
	lvl_scene.name_ref = name..levels:size()
	
	-- get level start and end
	local lvl_start = lvl_scene:getObjects("lvl_start")["layer0"][1]
	local lvl_end = lvl_scene:getObjects("lvl_end")["layer0"][1]
	
	-- if not the first level, offset it
	local offset = {last_lvl_end[1], last_lvl_end[2]}
	if name ~= 'spawn' then
		offset = {
			last_lvl_end[1] - lvl_start[1],
			last_lvl_end[2] - lvl_start[2]
		}
	end
	
	last_lvl_end = {
		last_lvl_end[1] + (lvl_end[1] - lvl_start[1]),
		last_lvl_end[2] + (lvl_end[2] - lvl_start[2])
	}
	
	-- spawn: get 'ready to play' and 'spawn' spot
	if name == 'spawn' and not main_penguin then
		main_penguin = Penguin(true)
		lvl_scene:addEntity("spawn", main_penguin, "top left")
		penguin_spawn = {x=main_penguin.x-10, y=main_penguin.y}
		main_penguin:netSync()
		
		destruct_ready_x = lvl_scene:getTiles("layer0", "ground_crack")[1].x
	end
	
	lvl_scene:addHitbox("ground")
	lvl_scene:translate(offset[1], offset[2])
	
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

Net.on('event', function(data)
	if data.event == "spawn_wall" then
		spawn_wall_count = spawn_wall_count + 1

		if spawn_wall_count >= Net.getPopulation() then
			startDestruction()
		end
		
	elseif data.event == "load_level" then
		loadLevel(data.info)
	end
end)