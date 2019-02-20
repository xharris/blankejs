-- engine
BlankE = require('blanke.Blanke')

function BlankE.load()
	BlankE.options = {
		state="PlayState",
		filter="nearest",
		resolution=4,
		debug={
			log=true,
			record=true
		}
	}

	-- Audio.setVolume(0)
end
