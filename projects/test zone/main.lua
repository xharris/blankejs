-- engine
BlankE = require('blanke.Blanke')

function BlankE.load()
	BlankE.options = {
		state="RepeaterState",
		plugins={"Pathfinder"},
		resolution=1,
		--filter="nearest",
		debug={
			log=true
		},
		inputs={
			{"lclick","mouse.1"},
			{"rclick","mouse.2"},
			{"move_l","left","a"},
			{"move_r","right","d"},
			{"move_u","up","w"},
			{"move_d","down","s"}
		}
	}
	
	Draw.setBackgroundColor("white")
end