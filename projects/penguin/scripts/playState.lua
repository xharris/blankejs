BlankE.addClassType("playState", "State")

play_mode = 'local'
game_start_population = 3
best_penguin = nil

local main_penguin

-- Called every time when entering the state.
function playState:enter(previous)
	wall = nil
	main_penguin = nil
	next_lvl_start = {0,0}
	last_lvl_end = {0,0}
	penguin_spawn = {}
	tile_snap = 32

	img_igloo_front = nil
	img_igloo_back = nil
	in_igloo_menu = false

	igloo_enter_x = 0
	destruct_ready_x = 0

	img_penguin = Image('penguin')
	Draw.setBackgroundColor('white2')
	water_color = hsv2rgb({212,70,100})

	bg_sky = Image('background')
	bg_sky.color = {0,0,210}
	img_igloo_front = Image("igloo_front")
	img_igloo_back = Image("igloo_back")

	igloo_enter_x = img_igloo_front.x + img_igloo_front.width - 25

	main_view = View()
	main_view.zoom_type = 'damped'
	main_view.zoom_speed = .05
	lvl_objects = Group()

	loadLevel("spawn")
	-- add player's penguin
	spawnPlayer()
end

local send_ready = false
function playState:update(dt)
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
			Net.send({
				type="netevent",
				event="spawn_wall"
			})
		end

		if play_mode == 'local' then
			startDestruction()
		end
	end

	-- player wants to enter igloo
	if main_penguin.x < igloo_enter_x then
		Net.disconnect()

		-- zoom in on igloo
		main_view:follow()
		main_view:moveToPosition(img_igloo_front.x + 90.25, img_igloo_front.y + img_igloo_front.height - (main_penguin.sprite['walk'].height / 2))

		-- transition to menu when zoomed in all the way
		if not in_igloo_menu and not wall then
			in_igloo_menu = true
			main_view:zoom(3, 3, function()
				State.transition(menuState, "circle-out")
			end)
		end

	elseif not Net.is_connected then
		Net.join()
		in_igloo_menu = false
		main_view:zoom(1)
		main_view:follow(main_penguin)
	end
	
	-- load more levels!
	if best_penguin.x > last_lvl_end[1] - (game_width/2) then
		loadLevel("level1")
	end
end

local spawn_wall_count = 0
function playState:draw()
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

		if not wall then img_igloo_back:draw() end
		Net.draw('Penguin')
		lvl_objects:call(function(o, obj)
			obj:draw()
			if main_penguin then main_penguin:draw() end 
		end)
		if not wall then img_igloo_front:draw() end
	end)
	local ready = ''
	if main_penguin.x > destruct_ready_x then ready = '\nREADY!' end
	Draw.text(tostring(Net.getPopulation())..' / '..tostring(game_start_population)..ready, game_width/2, 50)
end	

function loadLevel(name)
	local lvl_map = Map(name)
		    
    local lvl_start = lvl_map:getObjects("lvl_start")[1]
    local lvl_end = lvl_map:getObjects("lvl_end")[1]
	    
	local offset_x = (last_lvl_end[1])
	local offset_y = (last_lvl_end[2])
	if name ~= 'spawn' then
		offset_x = (last_lvl_end[1] - lvl_start.x)
		offset_y = (last_lvl_end[2] - lvl_start.y)
	end

	last_lvl_end[1] = last_lvl_end[1] + (lvl_end.x - lvl_start.x)
	last_lvl_end[2] = last_lvl_end[2] + (lvl_end.y - lvl_start.y)
    	
	-- regular ground
	local snapx, snapy = lvl_map.layer_info['layer0'].snap[1], lvl_map.layer_info['layer0'].snap[2]
    for o, obj in ipairs(lvl_map:getObjects("ground","cracked_ground")) do
		local ground_type = ''
		if obj.char == 'C' then 
			destruct_ready_x = obj.x
			ground_type = "cracked"
		end

        lvl_objects:add(Ground(
				obj.x+offset_x,
				obj.y+offset_y,
				bitmask4(lvl_map.array['layer0'], {'G','C'}, obj.x / snapx, obj.y / snapy), ground_type))
    end

	-- igloo
	if #lvl_map:getObjects("igloo") > 0 then
		local igloo_pos = lvl_map:getObjects("igloo")[1]
		lvl_objects:add(Ground(igloo_pos.x, igloo_pos.y, -1))
		img_igloo_front.x, img_igloo_front.y = igloo_pos.x, igloo_pos.y + tile_snap - img_igloo_front.height
		img_igloo_back.x, img_igloo_back.y = igloo_pos.x, igloo_pos.y + tile_snap - img_igloo_front.height

		penguin_spawn = {igloo_enter_x + 5, igloo_pos.y}
	end
	
	-- invisibile block
	for o, obj in ipairs(lvl_map:getObjects("invis_ground")) do
		lvl_objects:add(Ground(obj.x, obj.y, -1))
	end
end

function spawnPlayer()
	main_penguin = Penguin(true)
	main_penguin.x, main_penguin.y = unpack(penguin_spawn)
	main_penguin:netSync()
end

function startDestruction()
	if not wall then
		wall = DestructionWall()
		wall.x = -32

		FragImage(img_igloo_front)
		FragImage(img_igloo_back)
	end
end

function Net:onReady()
	Net.addObject(main_penguin)
end

Net.onEvent = function(data)
	if data.event == "spawn_wall" then
		spawn_wall_count = spawn_wall_count + 1

		if spawn_wall_count >= Net.getPopulation() then
			startDestruction()
		end
		
	elseif data.event == "load_level" then
		
	end
end