-- engine

BlankE = require('blanke.Blanke')

function love.load()
	Window.setResolution(1)
	
	Asset.add('scripts')
	Asset.add('assets')
	Asset.add('scenes')
	
	Input.set('move_left', 'left','a')
	Input.set('move_right', 'right','d')
	Input.set('jump', 'up','w')
	Input.set('restart', 'r')
	
	Input['jump'].can_repeat = false
	Input['restart'].can_repeat = false
	
	BlankE.loadPlugin("Platformer")
	
	BlankE.init("PlayState")
	
	BlankE.draw_debug = true
end