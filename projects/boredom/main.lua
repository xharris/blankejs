-- engine
BlankE = require('blanke.Blanke')

function love.load()
	Asset.add('scripts')
	Asset.add('assets')
	
	BlankE.init("PlayState")
end