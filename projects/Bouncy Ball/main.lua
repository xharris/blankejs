-- engine
BlankE = require('blanke.Blanke')

function BlankE.load()
	Input.set("move_left", "left")
	Input.set("move_right", "right")
	Input.set("move_up", "up")
	Input.set("move_down", "down")
	
	BlankE.options.state = "PlayState"
	--BlankE.options.filter = "nearest"
end