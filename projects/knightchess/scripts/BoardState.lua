BlankE.addState("BoardState")

local boards = {}
local board_index = 1
local size = 4
local cell_size = 50

BoardState.background_color = "white"

local font_goodnum = Font{size=50, align="center", limit=50}
local font_maybenum = Font{size=16, limit=50}

function BoardState:draw()	
	if Input("backward") then
		board_index = board_index - 1
		if board_index < 1 then
			board_index = 1
		end
	end
		
	if boards[board_index] then
		Draw.setColor("green")
		Draw.setFont(font_goodnum)
		Draw.text(board_index, 20, 20)
		
		local off_x = (game_width / 2) - (cell_size*size / 2)
		local off_y = (game_height / 2) - (cell_size*size / 2)
		
		Draw.translate(off_x, off_y)
		Draw.grid(size, size, cell_size, cell_size, function(x, y, realx, realy)
			-- draw cell
			Draw.setColor("grey")
			-- mouse hovering cell
			if mouse_x - off_x > x and mouse_x - off_x < x + cell_size - 5 and mouse_y - off_y > y and mouse_y - off_y < y + cell_size - 5 then
				Draw.setColor("baby_blue")
				
				if Input("forward") then
					boards[board_index+1] = table.copy(boards[board_index])
					boards[board_index+1][map2Dindex(realx, realy, size)] = board_index
					board_index = board_index + 1
				end
			end
				
			Draw.rect("fill", x, y, cell_size - 5, cell_size - 5)

			-- draw number
			Draw.setColor("black")
			local num = boards[board_index][map2Dindex(realx, realy,size)]
			if num ~= 0 then
				Draw.setFont(font_goodnum)
				Draw.text(num, x, y)
			end
		end)
	end
end

function BoardState:enter()
	Input.set("forward", "mouse.1")
	Input["forward"].can_repeat = false
	Input.set("backward", "mouse.2")
	Input["backward"].can_repeat = false
		
	-- fill the first board
	boards[1] = {}
	for x = 1, size do
		for y = 1, size do
			boards[1][map2Dindex(x,y,size)] = 0	
		end
	end
	
	Window.setResolution(1)
end