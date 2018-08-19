-- engine
BlankE = require('blanke.Blanke')

function love.load()
	BlankE.init("BoardState")
	BlankE.draw_debug = true
end