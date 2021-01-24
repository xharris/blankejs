Game {
  plugins = { 'xhh-array', 'xhh-badword', 'xhh-vector', 'xhh-effect' },
  auto_require = false,
  scripts = { 'scripts/vertex.lua' },
  initial_state = 'vertex',

  --scripts = { 'scripts/Bunnymark.lua' },
  --initial_state = 'bunnymark',

  background_color = 'brown',
  load = function() 

  --[[
	Image.animation(
	  'blue_robot.png',
	  { { rows=1, cols=8, frames={ '2-5' } } }
	)
  ]]

	  -- Game.effect = { 'static' }
  end,
  draw = function(d)
	d()
	Draw.color('red')
	Draw.rect('line',
	  Game.width/2-100,Game.height/2-100,
	  200,200
	)
    Draw.circle('line',mouse_x,mouse_y,10)
  end
}