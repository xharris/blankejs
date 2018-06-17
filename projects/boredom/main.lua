-- engine
BlankE = require('blanke.Blanke')

function love.load()
	Asset.add('scripts')
	Asset.add('assets')
	Asset.add('scenes')
	
	BlankE.init("PlayState")
end