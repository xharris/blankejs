BlankE.addState("DeckEditor")

local catalog, card_preview, deck
local img_back_arrow = Image("arrow")
local test_card
local editor_margin = 10
local fnt_name = Font{size=32}
local current_deck_name = "deck1"
local decks = {}

function loadDeck(deck_name)
	current_deck_name = deck_name
	deck:clearCards()
	for i, card_hash in ipairs(decks[current_deck_name]) do
		deck:addCard(Card(card_hash):useInfo(card_info))
	end
end

function saveDeck(deck_name)
	decks[deck_name] = deck:getCardsList()
	Save.write("decks",decks)
end

function DeckEditor:enter(prev_state)
	self.prev_state = prev_state
	
	-- card preview for both deck and catalog
	card_preview = Card()
	card_preview:setSize("L")
	
	-- card catalog
	catalog = CardCatalog()
	catalog:setSize((game_width / 2) - (editor_margin * 2), game_height - (editor_margin * 3) - card_preview.height)
				
	catalog.x =  (game_width / 2) + editor_margin
	catalog.y = editor_margin
	
	card_preview.x = (game_width * (.5 + .25)) - editor_margin - (card_preview.width / 2)
	card_preview.y = game_height - card_preview.height - editor_margin
	
	for i = 1, #Card.cards do
		local new_card = Card(i)
		catalog:addCard(new_card)
	end
	
	-- user's deck
	deck = CardCatalog()
	deck:setSize((game_width / 2) - (editor_margin * 2), game_height - (editor_margin*3) - (fnt_name:getHeight()*2))
	deck.x = editor_margin
	deck.y = (editor_margin*2) + fnt_name:getHeight()
	
	-- back arrow
	img_back_arrow.x = (editor_margin * 2) + img_back_arrow.width
	img_back_arrow:setScale(2)
	img_back_arrow.angle = 90
	img_back_arrow.y = (deck.y / 2) - (img_back_arrow.width / 2)
	
	-- inspect card in catalog
	function catalog:onCardSelect(card_info)
		card_preview:useInfo(card_info)
	end
	-- adding a card from catalog to deck
	function catalog:onCardAction(card_info)
		deck:addCard(Card(card_info.hash))
	end
	
	-- inspect card in user deck
	function deck:onCardSelect(card_info)
		card_preview:useInfo(card_info)
	end
	-- remove card from deck
	function deck:onCardAction(card_info, c)
		deck:removeCardIndex(c)
	end
	
	-- load decks from file
	Save.open("decks.json")
	decks = Save.read("decks")
	if decks == nil then decks = {deck1 = {}} end
		
	if Save.has_key("current_deck") then
		current_deck_name = Save.read("current_deck")
	else
		currend_deck_name = table.keys(decks)[1]
	end
	
	loadDeck(current_deck_name)
end

function DeckEditor:update(dt)

end

function DeckEditor:draw()
	Draw.reset()
	
	-- deck name
	Draw.setColor("black")
	fnt_name:draw(current_deck_name,img_back_arrow.x + img_back_arrow.width + editor_margin, editor_margin)
	
	-- back button
	if Input("primary").released and UI.mouseInside(img_back_arrow.x - img_back_arrow.height,img_back_arrow.y,img_back_arrow.height,img_back_arrow.width) then
		if self.prev_state then
			State.switch(self.prev_state)
		end
	end
	
	-- save button
	fnt_name:draw("SAVE", deck.x, deck.y+deck.height+editor_margin)
	Draw.setColor("red")
	if Input("primary").released and UI.mouseInside(deck.x, deck.y+deck.height+editor_margin, fnt_name:getWidth("SAVE"), fnt_name:getHeight()) then
		saveDeck(current_deck_name)
	end
	
	-- add previewed card to deck
	if Input("secondary").released and UI.mouseInside(card_preview.x, card_preview.y, card_preview.width, card_preview.height) then
		deck:addCard(card_preview:copy())
	end
	
	catalog:draw()
	deck:draw()
	card_preview:draw()
	img_back_arrow:draw()
end