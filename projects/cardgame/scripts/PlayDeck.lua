BlankE.addEntity("PlayDeck")

function PlayDeck:init(name)
	self.draw_pile = Group()
	self.trash_pile = Group()
	
	if name then
		
	end
end

function PlayDeck:load(name)
	self.name = "deck1"
	deck:clearCards()
	for i, card_hash in ipairs(decks[self.name]) do
		deck:addCard(Card(card_hash):useInfo(card_info))
	end
end

function PlayDeck:addCard(new_card)
	new_card:setSize("S")
	self.draw_pile:add(new_card)
end
	
function PlayDeck:drawCard(i)
	-- get a particular card
	if i then
			
	else
	-- draw top card
			
	end
end
function PlayDeck:shuffle() end
function PlayDeck:toggleDisplayList() end
function PlayDeck:insertCard() end