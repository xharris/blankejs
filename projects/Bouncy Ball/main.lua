-- engine
BlankE = require('blanke.Blanke')

function BlankE.load()
	Input.set("move_left", "left", "a")
	Input.set("move_right", "right", "d")
	Input.set("move_up","up", "w")
	Input.set("move_down","down", "s")
	Input.set("restart","r")
	
	BlankE.options.state = "PlayState"
	
	BlankE.options.resolution = 1
	BlankE.options.filter = "nearest"
end