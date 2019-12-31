Game {
	plugins = { "xhh-net" },
	load = function() 
		Map.load("map0.map")
		Net.connect()
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
		net = true,
		update = function(self, dt)
			if Input.released('action') then
				State.stop()
				State.start('play')
			end
		end
})