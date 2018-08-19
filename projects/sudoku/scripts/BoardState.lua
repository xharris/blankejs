BlankE.addState("BoardState")

local board = {
	0,0,0, 8,0,0, 0,0,7,
	0,0,6, 0,7,0, 0,0,0,
	8,0,0, 9,0,2, 3,0,0,

	0,0,0, 2,0,3, 0,0,0,
	0,0,0, 0,0,0, 0,0,9,
	0,4,2, 0,1,0, 0,0,0,

	0,1,0, 3,0,0, 0,0,5,
	0,6,8, 1,2,0, 0,4,0,
	0,7,5, 0,0,0, 9,0,0	
}
local history = {}
local history_index = 1

BoardState.background_color = "white"

local font_goodnum = Font{size=50, align="center", limit=50}
local font_maybenum = Font{size=16, limit=50}

function BoardState:draw()
	if Input("forward") then 
		history_index = history_index + 1
		if history_index > #history then
			history_index = #history
		end
	end
	
	if Input("backward") then
		history_index = history_index - 1
		if history_index < 1 then
			history_index = 1
		end
	end
	
	local size = 50
	
	if history[history_index] then
		Draw.setColor("green")
		Draw.setFont(font_goodnum)
		Draw.text(history_index, 20, 20)
		
		local off_x = (game_width / 2) - (size*9 / 2)
		local off_y = (game_height / 2) - (size*9 / 2)
		
		Draw.translate(off_x, off_y)
		Draw.grid(9, 9, size, size, function(x, y, realx, realy)
			-- draw cell
			Draw.setColor("grey")
			-- mouse hovering cell
			if history_index == 1 and mouse_x - off_x > x and mouse_x - off_x < x + size - 5 and mouse_y - off_y > y and mouse_y - off_y < y + size - 5 then
				Draw.setColor("baby_blue")
				
				local in_number = Input("number")
				if in_number then
					board[map2Dindex(realx, realy, 9)] = tonumber(in_number[1])
					generateSteps()
				end
			end
				
			Draw.rect("fill", x, y, size - 5, size - 5)

			-- draw number
			Draw.setColor("black")
			local num = history[history_index][map2Dindex(realx, realy,9)]
			if type(num) == "number" and num > 0 then 
				Draw.setFont(font_goodnum)
				Draw.text(num, x, y)
			elseif type(num) == "table" then
				Draw.setFont(font_maybenum)
				Draw.text(table.join(num, ','), x, y)
			end
		end)

		-- draw smaller rectangles
		Draw.setColor("black")
		Draw.setLineWidth(5)
		Draw.grid(3,3,size*3,size*3,function(x,y)
			Draw.rect("line", x - 2.5, y - 2.5, size*3, size*3)		
		end)
	end
end

function BoardState:enter()
	Input.set("forward", "mouse.1")
	Input["forward"].can_repeat = false
	Input.set("backward", "mouse.2")
	Input["backward"].can_repeat = false
	Input.set("number", "1", "2", "3", "4", "5", "6", "7", "8", "9")
	Input["number"].can_repeat = false
	
	-- attempt to solve
	generateSteps()
end

function generateSteps()
	history = {}
	history_index = 1
	last_empty_count = -1
	local h_index = 0
	repeat
		h_index = h_index + 1
		history[h_index] = table.deepcopy(board)
	until (not solveStep(h_index))
end

local last_empty_count = -1
function solveStep(h, skip_clean_blocks)	
	function checkBlock(i)
		local valid_nums = {}
		for n = 1, 9 do valid_nums[n] = true end
		
		local x, y = map2Dcoords(i, 9)
		-- check that column
		for cy = 1, 9 do
			local index = map2Dindex(x,cy, 9)
			valid_nums[history[h][index]] = false
		end
		-- check that row
		for cx = 1, 9 do
			local index = map2Dindex(cx,y, 9)
			valid_nums[history[h][index]] = false
		end
		-- check mini block
		local start_x, start_y = x - (x % 4) - 1, y - (y % 4) - 1
		if x < 3 or start_x < 1 then start_x = 1 end
		if y < 3 or start_y < 1 then start_y = 1 end
		
		for m = 1,9 do
			local mx, my = map2Dcoords(m, 3)
			local new_m = map2Dindex(mx+start_x-1, my+start_y-1, 9)
			valid_nums[history[h][new_m]] = false
		end
	
		-- return results
		local ret_nums = {}
		for k, v in pairs(valid_nums) do
			if v then table.insert(ret_nums, k) end
		end
		
		return ret_nums
	end
	
	local empty_count = 0
	for b, val in ipairs(history[h]) do
		if history[h][b] == 0 or type(history[h][b]) == "table" then 
			history[h][b] = checkBlock(b)
			empty_count = empty_count + 1
		end
	end
	
	-- confirm blocks with only one possibility
	if not skip_clean_blocks then
		for b, val in ipairs(history[h]) do
			if type(history[h][b]) == "table" and #history[h][b] == 1 then
				history[h][b] = history[h][b][1]
				solveStep(h, true)
			end
		end
	end
	
	if empty_count ~= last_empty_count then
		last_empty_count = empty_count
		return true
	end
	return false
end