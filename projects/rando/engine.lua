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
discard = Array()
hand_limit = 7
hands = {} -- { netid/self = '1', 'skip', 'draw', 'reverse' }
player_turn = 1 -- whose turn is it
win_hand_size = 1

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
	deck = discard
	discard = Array()
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

function play(card, player)
	player = player or Net.id
	discard:push(card)
	hands[player]:filter(function(c) return c ~= card end)
	print(player, 'plays', card)
end

function randomize(player)
	if player then
		local card = hands[player]:random()
		local old_card = tostring(card)
		card:randomize()
		print(player..'\'s card',old_card,'turned into',card)
	end
end