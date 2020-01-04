Game {
	load = function() 
		Net.on('ready', function()	
			Game.spawn('player') -- Map.load("map0.map")	
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
		align = "center",
		x = 150,
		y = 150,
		t = 1,
		update = function(self, dt)
			self.t = self.t + 1
			if Input.released('action') and not self.net_obj then
				self.x = self.x + self.width
								
				self.scalex = self.scalex - 0.5
				self.angle = self.angle + 90
				print(self.angle)
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