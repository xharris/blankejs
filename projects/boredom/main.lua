-- engine

BlankE = require('blanke.Blanke')

function love.load()
	Window.setResolution(2)
	
	Input.set('move_left', 'left','a')
	Input.set('move_right', 'right','d')
	Input.set('action', 'space')
	Input.set('jump', 'up','w')
	Input.set('restart', 'r')
	
	BlankE.loadPlugin("Platformer")
	
	BlankE.init("PlayState")
	
	BlankE.draw_debug = true
end