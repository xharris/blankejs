Image.animation("blue_robot.png", {}, { rows=1, cols=8, frames={ '2-5' } })

Input {
	action = { "space" }	
}

Entity("player", {
		animations = { "blue_robot" },
		animation = "blue_robot",
		net = true,
		align = "center",
		debug=true,
		t = 1,
		spawn = function(self)
			self.txt = Game.spawn("player_txt")
		end,
		update = function(self, dt)
			self.t = self.t + 1
			if Input.released('action') and not self.net_obj then
				--self.x = self.x + self.width
				--self.scalex = self.scalex - 0.5
				self.angle = self.angle + 20
			end
		end,
		postdraw = function(self)
			self.txt:draw()
		end
})

Entity("player_txt",{
		scale=1,
		align="center",
		debug=true,
		spawn = function(self)
			self:remDrawable()
			self.width = 80
			self.height = 20
		end,
		draw = function(self)
			Draw{
				{ 'color', 'red' },
				{ 'print', 'x:'..self.x..' y:'..self.y, 0,0}
			}
		end
})

State("entitytest",{
	enter = function()
		print(badword.check("thesh!tmatwinkien"))
		Map.load("map0.map")
		Net.on('ready', function()	
			Game.spawn('player') -- Map.load("map0.map")	
		end)
		Net.connect()	
	end
})