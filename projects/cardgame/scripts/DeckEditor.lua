BlankE.addState("DeckEditor")

local catalog, deck
local test_card

function DeckEditor:enter()
	catalog = CardCatalog()
	catalog.x = 50
	catalog.y = 50
	
	for i = 0, 50 do
		catalog:addCard(Card())
	end
end

function DeckEditor:draw()
	catalog:draw()
end