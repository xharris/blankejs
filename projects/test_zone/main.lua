Game {
	plugins = { 'xhh-array', 'xhh-badword' },
	load = function() 
		print(badword.check("thesh!tmatwinkien"))
		Map.load("map0.map")
		--[[
		Net.on('ready', function()	
			Game.spawn('player') -- Map.load("map0.map")	
		end)
		Net.connect()]]
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
		t = 1,
		update = function(self, dt)
			self.t = self.t + 1
			if Input.released('action') and not self.net_obj then
				--self.x = self.x + self.width
				--self.scalex = self.scalex - 0.5
				self.angle = self.angle + 90
			end
		end,
		postdraw = function(self)
			Draw{
				{ 'color', 'red' },
				{ 'print', 'x:'..self.x..' y:'..self.y, 0,0}
			}
		end
})