local part, img_bunny, rob

State("particles",{
	enter = function()
		-- img_bunny = Image{file="bunny.bmp", x=Game.width/2, y=Game.height/2}
		rob = BlueRobot{			
			x = Game.width / 2,
			y = Game.height / 2,
		}
		
		part = Particles{
			source = "bunny.bmp",
			rate = 1,
			lifetime = 20,
			-- speed = -10,
			linear_accel = { 10, 0 },
			color = { {1,1,1,0.25}, {1,1,1,0} },
			position = { Game.width /2, Game.height /2 },
			spin = { -Math.rad(30), Math.rad(30) },
			offset = { 26 / 2, 37 / 2 },
			sping_var = 0.5,
			max = 100000,
			insert = "bottom"
		}
	end,
	update = function(dt)
		-- rob.x = mouse_x
		-- rob.y = mouse_y
		--part:position(mouse_x, mouse_y)
	end
})

BlueRobot = Entity("BlueRobot",{
	animations = { "blue_robot" },
	align = 'center'
})
