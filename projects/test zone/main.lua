-- engine
BlankE = require('blanke.Blanke')

function love.load()
	BlankE.draw_debug = true
	
	Asset.add('scripts')
	BlankE.init("MainState")
end