-- engine
BlankE = require('blanke.Blanke')

function BlankE.load()
	BlankE.options = {
		state="PlayState",
		resolution=3,
		--filter="nearest",
		inputs={
			{"moveL","a"},
			{"moveR","d"},
			{"moveU","w"},
			{"moveD","s"},
			
			{"aimL","left"},
			{"aimR","right"},
			{"aimU","up"},
			{"aimD","down"},
			{"aimLU","left-up"},
			{"aimRU","right-up"},
			{"aimLD","left-down"},
			{"aimRD","right-down"},
			
			{"click","mouse.1","pad.6"},
			{"action1","1"},
			{"action2","2"},
			{"action3","3"}
		},
		input={
			no_repeat={"click"}	
		},
		debug={log=true}
	}
	Input.deadzone = 0.1
end