-- engine
BlankE = require('blanke.Blanke')

function love.load()
	BlankE.loadPlugin('Platformer')
	
	Asset.add('assets/hats/','hat')
	
	Scene.tile_hitboxes = {"ground"}
	Scene.hitboxes = {"ground"}

  	BlankE.init('MenuState')
	Window.setResolution(1)

	Input.set('menu_up', 'w', 'up')
	Input.set('menu_down', 's', 'down')
	Input.set('confirm', 'e')
	
	Input.set('player_left', 'a', 'left')
	Input.set('player_right', 'd', 'right')
	Input.set('player_up', 'w', 'up')
		
	Input.set('emote1', '1')

	Input.set("net_join", "j")
	Input.set("net_leave", "d")
	Input.set("destruct", "k")
	Input.set("restart", "r")
	
	BlankE.draw_debug = true
end