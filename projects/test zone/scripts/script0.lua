BlankE.addState("MainState")

local lines_mask
local offset = 0

function MainState:enter()
	Draw.setBackgroundColor("white")
	lines_mask = Mask("replace")
end

function MainState:draw()	
	if offset % 50 == 0 then offset = 0 end
	offset = offset + 1
	
	lines_mask.fn = function()
		half_w = game_width / 2
		local p
		for x = 50 - offset, half_w, 50 do
			p = (x / half_w) * 50
			
			Draw.rect("fill", x, 0, p, game_height)
		end
		for x = half_w + offset, game_width, 50 do
			p = ((x - half_w) / half_w) * 50
			
			Draw.rect("fill", x, 0, 50 - p, game_height)
		end
		
		half_h = game_height / 2
		for y = 50 - offset, half_h, 50 do
			p = (y / half_h) * 50
			
			Draw.rect("fill", 0, y, game_height, p)
		end
		for y = half_h + offset, game_height, 50 do
			p = ((y - half_h) / half_h) * 50
			
			Draw.rect("fill", 0, y, game_height, 50 - p)
		end
	end
	
	lines_mask:on()

	Draw.setColor("green")
	Draw.circle("fill", game_width/2, game_height/2, math.min(game_width, game_height)/2)
	
	lines_mask:off()
	
	Draw.rect("fill", game_width/2 - 50, game_height/2 - 50, 100, 100)
end