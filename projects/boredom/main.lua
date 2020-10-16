Game { 
  fps = 60,
  filter = 'nearest',
  plugins = { 'xhh-effect', 'xhh-tween' },
  background_color = "white",
  load = function()
	State.start('play')
  end
}

Map.config = {
  tile_hitbox = { 
	ground='ground',
	spike='death'
  }
}

Hitbox.config.reactions = {
  living = {
	ground = 'slide',
	death = 'slide'
  }
}

local map

Input.set({
  left = { "left", "a", "gp.dpleft" },
  right = { "right", "d", "gp.dpright" },
  jump = { "up", "w", "gp.a" },
  action = { "space", "gp.b" },	
})

State("play", {
  enter = function()
	map = Map.load('level1.map')
  end
})