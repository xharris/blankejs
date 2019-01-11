-- engine
BlankE = require('blanke.Blanke')

function love.load()
	BlankE.init("PlayState",{
		filter="linear"	
	})
	
	BlankE.draw_debug = true
end