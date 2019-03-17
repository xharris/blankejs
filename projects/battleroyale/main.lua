-- engine
BlankE = require('blanke.Blanke')

function BlankE.load()
	BlankE.options = {
		state="PlayState",
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
			
			{"click","mouse.1"},
			{"action1","1"},
			{"action2","2"},
			{"action3","3"}
		}
	}
end