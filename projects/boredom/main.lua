-- engine

BlankE = require('blanke.Blanke')

function love.load()
	Asset.add('scripts')
	Asset.add('assets')
	Asset.add('scenes')
	
	Input.set('move_left', 'left','a')
	Input.set('move_right', 'right','d')
	Input.set('jump', 'up','w')
	
	BlankE.loadPlugin("Platformer")
	
	BlankE.init("PlayState")
end