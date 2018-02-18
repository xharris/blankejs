-- engine
BlankE = require('blanke.Blanke')

function love.load()
	Asset.add('assets/image/')
	Asset.add('assets/hats/','hat')
	Asset.add('assets/levels/')
	Asset.add('maps/')
	Asset.add('scripts/')

	UI.color('window_bg', Draw.baby_blue)
	UI.color('window_outline', Draw.blue)
	UI.color('element_bg', Draw.dark_blue)

    BlankE.init('menuState')

	Input.setGlobal('confirm', 'e')
	Input.global_keys['confirm'].can_repeat = false

	BlankE.draw_debug = true
end