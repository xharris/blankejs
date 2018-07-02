BlankE.addState("PlayState")

local board

function PlayState:enter()
	Draw.setBackgroundColor('white')

	board = Board(10)
	board:addPlayer(5, 5)
	board:startMoveSelect()
end

function PlayState:draw()
	board:draw()
end