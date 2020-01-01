Game {
	load = function() 
		Net.on('ready', function()	
			Map.load("map0.map")	
		end)
		Net.connect()
	end
}

Image.animation("blue_robot.png", {}, { rows=1, cols=8, frames={ '2-5' } })

Input {
	action = { "space" }	
}

Entity("player", {
		animations = { "blue_robot" },
		animation = "blue_robot",
		net = true,
		update = function(self, dt)
			if Input.released('action') and not self.net_obj then
				self.x = self.x + self.width
			end
		end,
		draw = function(self, d)
			d()
			Draw{
				{ 'color', 'red' },
				{ 'circle', 'line', self.x, self.y, 2}
			}
		end
})