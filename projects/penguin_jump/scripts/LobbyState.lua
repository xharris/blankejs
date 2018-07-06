BlankE.addState("LobbyState")

local board= nil
main_player = nil
local join_timer

function LobbyState:enter()
	Draw.setBackgroundColor('white')
	
	Net.join('localhost')
end

function LobbyState:update(dt)
	if main_player and Input('select') then
		main_player:moveTowardsPoint(mouse_x, mouse_y, 200)
		main_player.friction = 3
	end
end

function LobbyState:draw()
	Draw.setColor('black')
	--Draw.text(join_timer.countdown, game_width-20, 20)
	Net.draw('Player')
	
	if main_player then
		main_player:draw()
	end
end

Net.on('ready', function()
	join_timer = Timer(5)
	join_timer:after(function()
		if Net.is_leader then
			Net.event('start_game')
		end
	end)
		
	join_timer:start()
	main_player = Player()
	main_player.persistent = true
	local margin = 100
	main_player.x = randRange(margin, game_width - margin)
	main_player.y = randRange(margin, game_height - margin)
	Net.addObject(main_player)
	main_player:netSync('color')
end)

Net.on('connect', function(clientid)
	if Net.is_leader and clientid ~= Net.id then
		join_timer.time = join_timer.time-- - 5
		Net.event('timer_sync',join_timer.time)
	end
end)

Net.on('event', function(data)
	if data.event == 'timer_sync' then
		join_timer.time = data.info
		if not join_timer.running then join_timer:start() end
	end
	if data.event == 'start_game' then
		State.switch('PlayState')	
	end
end)