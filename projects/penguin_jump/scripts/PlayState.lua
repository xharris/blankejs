BlankE.addState("PlayState")

local board

function PlayState:enter()
	if Net.is_leader then
		local client_positions = {}
		local client_list = Net.getClients()
		for c, client in ipairs(client_list) do
			-- place the clients around the board
		end
		Net.event('setup_board',{
			board_size=(Net.getPopulation() * 5),
			positions=client_positions
		})
	end
	Net.on('event', function(data)
		if data.event == 'setup_board' then

			board = Board(data.info.board_size)
			board:replacePlayer(main_player)	
			
		end
	end)
end

function PlayState:draw()
	if board then
		board:draw()
	end
end
