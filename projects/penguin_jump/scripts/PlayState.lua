BlankE.addState("PlayState")

local board
local MAX_SIZE = 20

function PlayState:enter()	
	if Net.is_leader then
		local client_positions = {}
		local client_list = Net.getClients()
		local population = Net.getPopulation()
		local size = population * 5
		
		if size > MAX_SIZE then size = MAX_SIZE end
		
		local columns = math.ceil(size / population)
		local spacing = math.ceil(size / columns)
		
		-- place the clients around the board
		local c = 1
		for c = 1, population do
			local valid = true
			local column, row = map2Dcoords(c, columns)
			local position
			-- make sure a player isn't already assigned there
			repeat
				--Debug.log('x',x*spacing, x*spacing+spacing,'y',y*spacing, y*spacing+spacing)
				
				position = {
					column*spacing,--randRange(x*spacing, x*spacing+spacing),
					row--randRange(y*spacing, y*spacing+spacing)
				}
				
				for c2, pos in pairs(client_positions) do
					if c2 ~= client_list[c] and pos[1] == position[1] and pos[2] == position[2] then
						valid = false	
					end
				end
			until(valid)

			client_positions[client_list[c]] = {
				position[1], 
				position[2]}
		end
		
		Net.event('setup_board',{
			board_size=size,
			positions=client_positions
		})
	end
	Net.on('event', function(data)
		if data.event == 'setup_board' then
			board = Board(data.info.board_size)
			main_player.friction = 0
			main_player.speed = 0
			
			board:replacePlayer(main_player)
			board:movePlayer(data.info.positions[Net.id][1], data.info.positions[Net.id][2])
		end
	end)
	
end

function PlayState:draw()
	if board then
		board:draw()
	end
end
