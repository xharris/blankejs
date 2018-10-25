BlankE.addState("MainState")

local img_mask = Image("Basic Bird")
img_mask:setScale(6)
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

function MainState:enter()
	Draw.setBackgroundColor("white")
	test_mask.fn = function()
		test_mask:useImageAlphaMask(img_mask)
	end
	
	for i = 1, 30 do
		grp_elements:add(Element())
		grp_elements:get(i).index = i
	end
end

function MainState:draw()
	--[[ 
	test_mask:draw(function()
		Draw.setColor("white")
		Draw.rect("fill", 0, 0, game_width, game_height)
	end)
	]]
	
	ui_element_list:setSize(grp_elements:size())
	ui_element_list:draw()
end