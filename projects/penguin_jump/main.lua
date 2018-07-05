-- engine
BlankE = require('blanke.Blanke')

function love.load()
	Asset.add("scripts")
	
	Input.set("select", "mouse.1")
	
	BlankE.draw_debug = true
	BlankE.init("LobbyState")
end