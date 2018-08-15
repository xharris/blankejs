-- engine
BlankE = require('blanke.Blanke')

function love.load()
	BlankE.loadPlugin('Platformer')
	
	Asset.add('assets/hats/','hat')
	Asset.add('assets/image/')
	Asset.add('maps/')
	Asset.add('scenes/')
	Asset.add('scripts/')

	UI.color('window_bg', Draw.baby_blue)
	UI.color('window_outline', Draw.blue)
	UI.color('element_bg', Draw.dark_blue)

  	BlankE.init('PlayState')

	Input.set('menu_up', 'w', 'up')
	Input.set('menu_down', 's', 'down')
	Input.set('confirm', 'e')
	Input.keys['menu_up'].can_repeat = false
	Input.keys['menu_down'].can_repeat = false
	Input.keys['confirm'].can_repeat = false
	
	Input.set('player_left', 'a', 'left')
	Input.set('player_right', 'd', 'right')
	Input.set('player_up', 'w', 'up')
		
	Input.set('emote1', '1')
	Input.keys['player_up'].can_repeat = false
	Input.keys['emote1'].can_repeat = false

	Input.set("net_join", "j")
	Input.set("net_leave", "d")
	Input.set("destruct", "k")
	Input.set("restart", "r")
	Input.keys['restart'].can_repeat = false
	
	BlankE.draw_debug = true
end