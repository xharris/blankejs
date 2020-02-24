Input {
	action = { "space" }	
}

Entity("shader_player", {
		animations = { "blue_robot" },
		animation = "blue_robot",
		net = true,
		align = "center",
		debug=true,
		t = 1,
		scale = 3,
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
		Game.setBackgroundColor('white')
		
		Game.setEffect('chroma shift','static')
		--Game.effect:disable('chroma shift')
		
		print(badword.check("thesh!tmatwinkien"))
		Map.load("map0.map")
		Net.on('ready', function()	
			Game.spawn('shader_player', {x=Game.width/2, y=Game.height/2}) -- Map.load("map0.map")	
		end)
		Net.connect()	
	end,
	update = function(dt)
		--Game.effect:set("chroma shift", 'radius', (mouse_x / Game.width) * 10)
	end
})