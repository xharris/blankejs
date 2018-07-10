BlankE.addState("PlayState")

local board
local MAX_SIZE = 10
local size = 0

function PlayState:enter()	
	if Net.is_leader then
		local client_positions = {}
		local client_list = Net.getClients()
		local population = Net.getPopulation()
		size = population * 5
		
		if size > MAX_SIZE then size = MAX_SIZE end
		
		local columns = math.min(population, MAX_SIZE / 5)
		local spacing = math.ceil(size / columns)
		
		-- place the clients around the board
		local c = 1
		for c = 1, population do
			local valid = true
			local column, row = map2Dcoords(c, columns)
			local position
			-- make sure a player isn't already assigned there
			repeat				
				position = {
					column*spacing - math.floor(spacing/2),--randRange(x*spacing, x*spacing+spacing),
					row*spacing - math.floor(spacing/2)--randRange(y*spacing, y*spacing+spacing)
				}
				
				for c2, pos in pairs(client_positions) do
					if c2 ~= client_list[c] and pos[1] == position[1] and pos[2] == position[2] then
						valid = false	
					end
				end
			until(valid)
			client_positions[client_list[c]] = {position[1], position[2]}
		end
		
		Net.event('setup_board',{
			board_size=size,
			positions=client_positions
		})
	end
		
	Signal.on('finish_jump', function()
		Net.event("player_landed", board.player:getMoveInfo())
		board:checkBlockVis()
	end)
	
	local round = 1
	local shrink_time = 1 			-- shrink board every X rounds
	local moves_waiting = {}
	Net.on('event', function(data)
		-- board being created
		if data.event == 'setup_board' then
			assert(data.info.positions[Net.id], "player position not received")
			board = Board(data.info.board_size)
			main_player.friction = 0
			main_player.speed = 0
			
			board:replacePlayer(main_player)
			board:movePlayer(data.info.positions[Net.id][1], data.info.positions[Net.id][2])
		
		else
			-- board events
			if data.event == "start_jump" then		
				board:performMove()
			end
			if data.event == "attempting_jump" then
				if data.clientid ~= Net.id then moves_waiting[data.clientid] = data.info end

				-- check for conflicts
				if table.len(moves_waiting) == Net.getPopulation() - 1 then
					local can_resolve = true

					local net_players = Net.getObjects("Player")				
					for id, val in pairs(moves_waiting) do
						local other_player = net_players[id][1]
						if not board:checkMoveConflict(other_player) then				
							-- remove it from the conflict list
							moves_waiting[id] = nil	
							Net.event("resolved_jump")
						end

					end
					board:clearSelection()
				end
			end
			if data.event == "resolved_jump" then
				if moves_waiting[data.clientid] then moves_waiting[data.clientid] = nil end
				if table.len(moves_waiting) == 0 and Net.is_leader then

					-- shrink map?
					if board.size > Net.getPopulation() and round % shrink_time == 0 then
						Net.event("shrink_board", board.size - 2)
					end
					Net.event("start_move_select")

				end
			end
			if data.event == "start_move_select" then
				board:startMoveSelect()	
			end
			if data.event == "set.leader" then
				if (table.len(moves_waiting) == 0 or not board.move_timer.running) and Net.is_leader then
					Net.event("start_move_select")	
				end
			end
			if data.event == "shrink_board" then
				board:setSize(data.info)
			end
		end
	end)
	
	Net.on('disconnect', function(id)
		-- if a player disconnect after making a move, make sure the game doesnt wait on them to finish
		if moves_waiting[id] then moves_waiting[id] = nil end	
	end)
	
	-- start the game
	if Net.is_leader then
		Net.event("start_move_select")
	end
	
end

function PlayState:draw()
	if board then
		board:draw()
	end
end
