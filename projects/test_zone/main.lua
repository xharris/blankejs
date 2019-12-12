Game {
	load = function() 
		Game.spawn("player")
	end
}

Image.animation("blue_robot.png", {}, { rows=1, cols=8, frames={ '2-5' } })

Entity("player", {
	animations = { "blue_robot" },
	animation = "blue_robot"
})
