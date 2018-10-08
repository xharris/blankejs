-- engine
BlankE = require('blanke.Blanke')

function love.load()
	BlankE.draw_debug = true
	
	Draw.setBackgroundColor("white")
	BlankE.init("MainMenu")
end