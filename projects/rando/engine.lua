--[[ 
cards in uno deck:
- for all colors
	- one 0
	- two 1 - 9
	- two draw2 (draw)
	- two skip
	- two reverse
- four wild
- four wild draw4 (wilddraw)
]]

deck = Array()
discard_pile = Array()
hand_limit = 7
max_hand_size = 10
hands = {} -- { netid = '1', 'skip', 'draw', 'reverse' }
points = {} -- { netid = # }
player_turn = 1 -- whose turn is it

function newDeck()
	deck = Array()
	card_colors:forEach(function(color)
		for n = 0, 9 do
			if n ~= 0 then
				deck:push(tostring(n)..'.'..color)
			end
			deck:push(tostring(n)..'.'..color)
		end		
		for _,t in ipairs({ 'draw', 'skip', 'reverse' }) do
			deck:push(
				t..'.'..color,
				t..'.'..color
			)
		end
	end)
	for _,t in ipairs({ 'wild', 'wilddraw' }) do
		deck:push(t,t,t,t)
	end
	-- shuffle
	deck:shuffle()
	-- convert to card objects
	deck:map(function(c) return Game.spawn("Card", {c}) end)
end

-- shuffle discarded cards into deck
function refillDeck()
	deck = discard_pile
	discard_pile = Array()
	deck:shuffle()
	print('out of cards. shuffling discard pile into deck...')
end

function draw(num, player)
	player = player or Net.id
	if not hands[player] then
		hands[player] = Array()
	end
	for d = 1, num or 1 do 
		if deck.length == 0 then
			refillDeck()
		end
		hands[player]:push(deck:pop())
	end
	print(player, 'draws', hands[player])
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
		if points[player] > 500 then
			-- TODO: win
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