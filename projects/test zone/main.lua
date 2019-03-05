-- engine
BlankE = require('blanke.Blanke')

function BlankE.load()
	BlankE.options = {
		state="PathfindState",
		plugins={"Pathfinder"},
		filter="nearest",
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