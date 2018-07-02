BlankE.addState("PlayState")

local board

function PlayState:enter()
	Draw.setBackgroundColor('white')

	board = Board(10)
	board:addPlayer(5, 5)
end

function PlayState:draw()
	board:draw()
end