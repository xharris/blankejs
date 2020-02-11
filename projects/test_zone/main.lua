local points

Game {
	plugins = { 'xhh-array', 'xhh-badword' },
	load = function() 
		--print(badword.check("thesh!tmatwinkien"))
		Map.load("map0.map")
		--[[
		Net.on('ready', function()	
			Game.spawn('player') -- Map.load("map0.map")	
		end)
		Net.connect()]]
		points = Array(
			{x=-100, 	y=100, z=-100},
			{x=100,		y=100, z=-100},
			{x=100,		y=100, z=100},
			{x=-100,	y=100, z=100}
		)
	end,
	draw = function(d)
		local last_pt = points[points.length]
		
		Draw.translate(Game.width/2, Game.height/2)
		points:forEach(function(pt)
			local amt = Math.lerp(0,200,mouse_x / Game.width)
			local z = 1/(amt - pt.z)
				
			local last_z = amt/(amt + last_pt.z)
			Draw.line(last_pt.x, last_pt.y * last_z, pt.x, pt.y * z)
			last_pt = pt
		end)
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