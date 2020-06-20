local part, img_bunny

State("particles",{
	enter = function()
		-- img_bunny = Image{file="bunny.bmp", x=Game.width/2, y=Game.height/2}
		local rob = BlueRobot()
		
		part = Particles{
			source = "bunny.bmp",
			rate = 5,
			speed = 10
		}
		part.x = Game.width / 2 
		part.y = Game.height / 2
	end,
	draw = function()
		-- img_bunny:draw()
	end
})

BlueRobot = Entity("BlueRobot",{
	animations = { "blue_robot" }
})
