--[[ 
cards in uno draw_pile:
- for all colors
	- one 0
	- two 1 - 9
	- two draw2 (draw)
	- two skip
	- two reverse
- four wild
- four wild draw4 (wilddraw)
]]

draw_pile = Array()
discard_pile = Array()
hand_limit = 7
max_hand_size = 10
hands = {} -- { netid = '1', 'skip', 'draw', 'reverse' }
points = {} -- { netid = # }
player_turn = 1 -- whose turn is it
turn_direction = 'cw' -- or ccw

function newDeck()
	draw_pile = Array()
	card_colors:forEach(function(color)
		for n = 0, 9 do
			if n ~= 0 then
				draw_pile:push(tostring(n)..'.'..color)
			end
			draw_pile:push(tostring(n)..'.'..color)
		end		
		for _,t in ipairs({ 'draw', 'skip', 'reverse' }) do
			draw_pile:push(
				t..'.'..color,
				t..'.'..color
			)
		end
	end)
	for _,t in ipairs({ 'wild', 'wilddraw' }) do
		draw_pile:push(t,t,t,t)
	end
	-- shuffle
	draw_pile:shuffle()
	-- convert to card objects
	draw_pile:map(function(c) return Game.spawn("Card", {c}) end)
end

-- shuffle discarded cards into draw_pile
function refilldraw_pile()
	draw_pile = discard_pile
	discard_pile = Array()
	draw_pile:shuffle()
	print('out of cards. shuffling discard pile into draw_pile...')
end

function draw(num, player)
	player = player or Net.id
	if not hands[player] then
		hands[player] = Array()
	end
	for d = 1, num or 1 do 
		if draw_pile.length == 0 then
			refilldraw_pile()
		end
		hands[player]:push(draw_pile:pop())
	end
	sortHand(player)
	print(player, 'draws', hands[player])
end
	
function play(player, card)
	
end

function sortHand(player)
	player = player or Net.id
	if hands[player] then 
		hands[player]:sort(function(a,b)
			a = a.orig
			b = b.orig
			if a.value > -1 and b.value > -1 then
				if a.value == b.value then 
					return card_colors:indexOf(a.value) < card_colors:indexOf(b.value)
				end 
				return a.value < b.value	
			elseif a.value > -1 then
				return true	
			elseif b.value > -1 then
				return false	
			else
				if a.name == b.name then 
					return card_colors:indexOf(a.value) < card_colors:indexOf(b.value)
				else
					return card_names:indexOf(a.value) < card_names:indexOf(b.value) 
				end
			end
		end)
	end
end

function discard(card, player)
	player = player or Net.id
	discard_pile:push(card)
	hands[player]:filter(function(c) return c ~= card end)
	print(player, 'discards', card)
	-- one card left?
	if hands[player].length == 1 then
		print(player, 'has one card left')
	end
	if hands[player].length == 0 then
		print(player..'\'s hand is empty')
		-- tally points for player...
		for player_id, hand in pairs(hands) do
			hand:forEach(function(c)
				if c.name == 'number' then points[player] = points[player] + c.value
				elseif c.name == 'wilddraw' then points[player] = points[player] + 50
				else points[player] = points[player] + 20 end
			end)
		end
		if points[player] >= 500 then
			print(player,'wins with',points[player],'points')
		end
		-- and give new cards
		draw(4, player)
	end
end

function checkHandLimit()
	for player_id, hand in pairs(hands) do
		local count = 0
		while hand.length > hand_limit do
			discard(hand:random(), player_id)
			count = count + 1
		end
		if count > 0 then
			print(player_id,'lost',count,'cards')
		end
	end
end

function randomize(player)
	if player then
		-- change random card in player's hand
		local card = hands[player]:random()
		local old_card = tostring(card)
		card:randomize()
		print(player..'\'s card',old_card,'turned into',card)
	else
		-- change random game element
		switch(Math.random(1,1),{
			-- change hand size
			function()
				hand_limit = Math.random(math.max(hand_limit-2,4),math.min(hand_limit+2,max_hand_size))
				print('hand size limit is',hand_limit)
				checkHandLimit()
			end,
		})
	end
end