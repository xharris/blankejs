BlankE.addState("MainState")

local img_mask = Image("Basic Bird")
img_mask:setScale(2)
local test_mask = Mask()
test_mask:setup("inside")
local offset = 0

local effect = Effect("static")

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
	MainState.background_color = "white"
	
	mario = Mario()
	rptr = Repeater(img_mask)
	rptr.x = 50
	rptr.y = 100
	rptr.duration = 10
	rptr.speed = 50
	rptr.rate = 0.001
	
	test_mask.fn = function()
		test_mask:useImageAlphaMask(img_mask)
	end
	
	for i = 1, 30 do
		grp_elements:add(Element())
		grp_elements:get(i).index = i
	end
end

function MainState:draw()
	rptr.x = mouse_x
	rptr.y = mouse_y
	
	rptr:draw()
	mario.x = mouse_x
	mario.y = mouse_y
	mario:draw()
	
	Draw.setColor("black")
	Draw.text(rptr.count,10,10)
	--[[ effect.chroma_shift.radius = lerp(0,10,mouse_x/game_width)
	effect:draw(function()
		img_mask:draw()
	end)]]
end