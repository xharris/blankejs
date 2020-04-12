Game {
	-- plugins = { 'xhh-array', 'xhh-badword', 'xhh-vector', 'xhh-effect' },
	plugins = {'xhh-effect'},
	auto_require = false,
	scripts = { 'ecs' },-- 'bunnymark' },
	load = function() 
		--[[
		Animation(
			file="blue_robot.png", 
			{ name='walk', rows=1, cols=8, frames={ '2-5' } }
		)]]
 
		State.start('ecs')
	end,
	update = function(dt)
		print(System.stats())
	end
}