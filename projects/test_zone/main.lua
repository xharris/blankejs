Game {
	plugins = { 'xhh-array', 'xhh-badword', 'xhh-vector', 'xhh-effect' },
	--plugins = {'xhh-effect'},
	auto_require = false,
	
	scripts = { 'scripts/particles.lua' },
	initial_state = 'particles',
	
	--scripts = { 'scripts/Bunnymark.lua' },
	--initial_state = 'bunnymark',
	
	-- effect = { 'chroma shift' }, -- TODO get this to work
	background_color = 'white',
	load = function() 
		Image.animation(
			'blue_robot.png',
			{ { rows=1, cols=8, frames={ '2-5' } } }
		)
				
		-- Game.effect = { 'static' }
	end,
	--background_color="white",
}