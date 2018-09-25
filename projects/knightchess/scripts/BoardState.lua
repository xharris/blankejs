BlankE.addState("BoardState")

local my_board
local boards = {}
local board_index = 1
local size = 4
local cell_size = 50

BoardState.background_color = "white"

function BoardState:draw()	
	my_board:draw(function()
		
	end)
end


function BoardState:enter()
	Input.set("forward", "mouse.1")
	Input["forward"].can_repeat = false
	Input.set("backward", "mouse.2")
	Input["backward"].can_repeat = false
	Input.set("size_up", "=")
	Input["size_up"].can_repeat = false
	Input.set("size_down", "-")
	Input["size_down"].can_repeat = false
		
	my_board = Board()
	
	-- fill the first board
	Window.setResolution(1)
end