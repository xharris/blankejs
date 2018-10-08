BlankE.addState("MainMenu")

local test_card

function MainMenu:enter()
	test_card = DisplayCard()
	test_card.x = 50
	test_card.y = 50
end

function MainMenu:draw()
	test_card:draw()
end