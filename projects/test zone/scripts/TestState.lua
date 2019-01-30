BlankE.addState("TestState");

local img_penguin, img_sheet

function TestState:enter()
	Draw.setBackgroundColor('white')
	img_penguin = Image("Basic Bird")
	img_sheet = Image("sprite-example")
end

function TestState:update(dt)

end


local x, y = game_width/2, game_height/2
local my_mario = Mario()
my_mario.x = 0
my_mario.y = 0
local my_luigi = Mario()
local my_view = View(my_mario)

function TestState:draw()
	Draw.setColor("red")
	Draw.reset("color")
		
	my_view:draw(function()	
		img_penguin.x = game_width / 2
		img_penguin.y = game_height / 2
		img_penguin:draw()

		my_luigi.x = 0
		my_luigi.y = 0
		my_luigi:draw()

		Draw.setColor("blue")
		Draw.circle("line",my_mario.x,my_mario.y,50)
		Draw.reset("color")	
      	my_mario:draw()
	end)
end
