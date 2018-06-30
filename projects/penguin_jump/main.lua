-- engine
BlankE = require('blanke.Blanke')

function love.load()
	Asset.add("scripts")
	
	BlankE.init("PlayState")
end