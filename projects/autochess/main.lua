-- engine
BlankE = require('blanke.Blanke')

function love.load()
	BlankE.init("PlayState")
	BlankE.draw_debug = true
end