BlankE.addState("PlayState")

local board

function PlayState:enter()
	Draw.setBackgroundColor('white')

	board = Board()
	
end

function PlayState:draw()
end