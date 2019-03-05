-- engine
BlankE = require('blanke.Blanke')

function BlankE.load()
	BlankE.options = {
		state="PlayState",
		filter="nearest",
		plugins={"Pathfinder"},
		resolution=5,
		debug={
			log=true,
			record=true
		}
	}

	Audio.setVolume(0)
end
