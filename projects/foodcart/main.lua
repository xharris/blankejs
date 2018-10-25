-- engine
BlankE = require('blanke.Blanke')

function love.load()
	Input.set("primary", "mouse.1")
	
	Draw.setBackgroundColor("white")
	BlankE.init("PlayState")
	
	BlankE.draw_debug = True
end