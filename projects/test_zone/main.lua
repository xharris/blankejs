Game {
	load = function() 
		State.start('play')
	end
}

Image.animation("blue_robot.png", {}, { rows=1, cols=8, frames={ '2-5' } })

Input {
	action = { "space" }	
}

Entity("player", {
		animations = { "blue_robot" },
		animation = "blue_robot",
		hspeed = 50,
		update = function(self, dt)
			if Input.released('action') then
				State.stop()
				State.start('play')
			end
		end
})

State('play',{
		enter = function()
			Map.load("map0.map")
		end
})