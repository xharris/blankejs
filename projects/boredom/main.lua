-- engine

BlankE = require('blanke.Blanke')

function love.load()
	Asset.add('scripts')
	Asset.add('assets')
	Asset.add('scenes')
	
	BlankE.loadPlugin("Platformer")
	
	BlankE.init("PlayState")
end