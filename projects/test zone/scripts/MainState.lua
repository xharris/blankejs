BlankE.addState("MainState")

local img_mask = Image("Basic Bird")
img_mask:setScale(2)
local test_mask = Mask()
test_mask:setup("inside")
local offset = 0

local grp_elements = Group()
local ui_element_list = UI.list{
	x = 100, y = 100,
	item_width = 50,
	item_height = 50,
	max_height = game_height - 200,
	max_width = 50,
	fn_drawItem = function(i, x, y)
		local el = grp_elements:get(i)
		el.x = x
		el.y = y
		el:draw()
	end
}

local mario
local rptr
function MainState:enter()
	mario = Mario()
	rptr = Repeater(mario,{rate=100, lifetime=1})
	
	test_mask.fn = function()
		test_mask:useImageAlphaMask(img_mask)
	end
	
	for i = 1, 30 do
		grp_elements:add(Element())
		grp_elements:get(i).index = i
	end
end

function MainState:draw()
	rptr.spawn_x = mouse_x
	rptr.spawn_y = mouse_y
	
	rptr.end_color = {randRange(0,100)/100,randRange(0,100)/100,randRange(0,100)/100,0}

	rptr:draw()
	
	mario:draw()
	
	dt_mod = (mouse_x / game_width) * 5
	--[[ 
	test_mask:draw(function()
		Draw.setColor("white")
		Draw.rect("fill", 0, 0, game_width, game_height)
	end)
	
	img_mask.x = game_width / 2 --sinusoidal(game_width / 4, game_width - (game_width / 4), 0.5)
	
	ui_element_list:setSize(grp_elements:size())
	--ui_element_list:draw()
	]]
end