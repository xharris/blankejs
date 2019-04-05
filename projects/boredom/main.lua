-- engine

BlankE = require('blanke.Blanke')

function BlankE.load()
	
	Input.set('move_left', 'left','a')
	Input.set('move_right', 'right','d')
	Input.set('action', 'space')
	Input.set('jump', 'up','w')
	Input.set('restart', 'r')
		
	BlankE.loadPlugin("Platformer")
	
	BlankE.options = {
		state="PlayState",
		resolution = 1,
		--filter="nearest",
		debug = {
			log = true
		}
	}
end