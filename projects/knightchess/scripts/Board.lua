BlankE.addEntity("Board")

local font_goodnum = Font{size=50, align="center", limit=50}
local font_maybenum = Font{size=24, limit=50}
local size = 4

function Board:init()
	self.cell_size = 50
	self.boards = {}
	self.board_index = 1
	
	-- set up board
	self.boards[1] = {}
	for x = 1, size do
		for y = 1, size do
			self.boards[1][map2Dindex(x,y,size)] = 0	
		end
	end
end

function Board:draw(fn_drawcell)
	if Input("backward") then
		self.board_index = self.board_index - 1
		if self.board_index < 1 then
			self.board_index = 1
		end
	end
	
	if Input("size_up") then
		size = size + 1
		createBoard()
	end
	
	if Input("size_down") then
		if size > 4 then
			size = size - 1
			createBoard()
		end
	end
		
	if self.boards[self.board_index] then
		Draw.setColor("green")
		Draw.setFont(font_goodnum)
		Draw.text(self.board_index, 20, 20)
		
		local off_x = (game_width / 2) - (self.cell_size*size / 2)
		local off_y = (game_height / 2) - (self.cell_size*size / 2)
		
		Draw.translate(off_x, off_y)
		Draw.grid(size, size, self.cell_size, self.cell_size, function(x, y, realx, realy)
			-- draw cell
			Draw.setColor("grey")
			-- mouse hovering cell
			if mouse_x - off_x > x and mouse_x - off_x < x + self.cell_size - 5 and mouse_y - off_y > y and mouse_y - off_y < y + self.cell_size - 5 then
				Draw.setColor("baby_blue")
				
				if Input("forward") then
					self.boards[self.board_index+1] = table.deepcopy(self.boards[self.board_index])
					local val = self.boards[self.board_index][map2Dindex(realx, realy, size)]
					if val == 0 then
						self.boards[self.board_index+1][map2Dindex(realx, realy, size)] = {self.board_index}
					else
						table.insert(self.boards[self.board_index+1][map2Dindex(realx, realy, size)], self.board_index)
					end
					self.board_index = self.board_index + 1
				end
			end
				
			Draw.rect("fill", x, y, self.cell_size - 5, self.cell_size - 5)

			-- draw number
			Draw.setColor("black")
			local num = self.boards[self.board_index][map2Dindex(realx, realy,size)]
			if num ~= 0 then
				if #num > 1 then
					Draw.setFont(font_maybenum)
					Draw.text(table.join(num,','), x, y)
				else
					Draw.setFont(font_goodnum)
					Draw.text(num, x, y)	
				end
			end
				
		end)
	end
end