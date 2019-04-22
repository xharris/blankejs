-- engine
BlankE = require('blanke.Blanke')

function BlankE.load()
	Input.set("move_left", "left")
	Input.set("move_right", "right")
	
	BlankE.options.state = "PlayState"
end