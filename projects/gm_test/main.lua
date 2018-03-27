-- engine
BlankE = require('blanke.Blanke')

function love.load()
	Asset.add('scripts/')
	BlankE.draw_debug = true
	BlankE.init("mainState")
end
