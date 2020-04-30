Game {
	plugins = { 'xhh-array', 'xhh-badword', 'xhh-vector', 'xhh-effect' },
	--plugins = {'xhh-effect'},
	scripts = { 'ecstest' },
	initial_state = 'ecs',
	load = function() 
		
		Animation{
			file="blue_robot.png", 
			{ name='walk', rows=1, cols=8, frames={ '2-5' } }
		}
			
		--[[
		Image.animation(
			'blue_robot.png',
			{ { rows=1, cols=8, frames={ '2-5' } } }
		)
		]]
		-- Game.effect = { 'static' }
	end,
	--background_color="white",
}