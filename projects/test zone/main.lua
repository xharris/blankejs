-- engine
BlankE = require('blanke.Blanke')

function love.load()
	BlankE.draw_debug = true
	
	Input.set("lclick","mouse.1")
	Input.set("rclick","mouse.2")
	
	BlankE.init("MainState")
end