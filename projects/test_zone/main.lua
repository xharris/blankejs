Game {
	plugins = { 'xhh-array', 'xhh-badword', 'xhh-vector', 'xhh-effect' },
	--plugins = {'xhh-effect'},
	auto_require = false,
	scripts = { 'scripts/Bunnymark.lua' },
	initial_state = 'bunnymark',
	-- effect = { 'chroma shift' }, -- TODO get this to work
	background_color = 'white',
	load = function() 
		--[[
		Animation{
			file="blue_robot.png", 
			{ name='walk', rows=1, cols=8, frames={ '2-5' } }
		}]]
			 
		--
		Image.animation(
			'blue_robot.png',
			{ { rows=1, cols=8, frames={ '2-5' } } }
		)
				
		-- Game.effect = { 'static' }
	end,
	--background_color="white",
}