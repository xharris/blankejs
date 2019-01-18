BlankE.addState("PlayState");

local test_board

function PlayState:enter()
	test_board = Board()
end

function PlayState:update(dt)

end

function PlayState:draw()
	test_board:draw()
end
