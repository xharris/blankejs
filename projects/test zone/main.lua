-- engine
BlankE = require('blanke.Blanke')

function love.load()
	BlankE.draw_debug = true
	
	Input.set("lclick","mouse.1")
	Input.set("rclick","mouse.2")
	
	Input.set("move_l","left","a")
	Input.set("move_r","right","d")
	Input.set("move_u","up","w")
	Input.set("move_d","down","s")
		
	BlankE.init("TestState",{
		plugins={"Platformer"}	
	})
	
	Draw.setBackgroundColor("white")
end