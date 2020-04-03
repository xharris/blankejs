Game {
	plugins = { 'xhh-array', 'xhh-badword', 'xhh-vector', 'xhh-effect' },
	load = function() 
		Image.animation(
			"blue_robot.png", { { 
				rows=1, cols=8, frames={ '2-5' } 
			} }
		)
 
		State.start('platformer')
	end,
	update = function(dt)
		-- Cache.stats()
	end
}