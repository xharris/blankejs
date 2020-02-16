Image.animation("blue_robot.png", {}, { rows=1, cols=8, frames={ '2-5' } })

Input {
	action = { "space" }	
}

Effect.new("chroma shift2", {
    vars = { angle=0, radius=2, direction={0,0} },
    blend = {"replace", "alphamultiply"},
    effect = [[

      vec4 px_minus = Texel(texture, texture_coords - direction);
      vec4 px_plus = Texel(texture, texture_coords + direction);
      pixel = vec4(px_minus.r, pixel.g, px_plus.b, pixel.a);
      if ((px_minus.a == 0 || px_plus.a == 0) && pixel.a > 0) {
          //pixel.a = 1.0;
      }
    ]],
    draw = function(vars, applyShader)
      dx = (math.cos(math.rad(vars.angle)) * vars.radius) / Game.width
      dy = (math.sin(math.rad(vars.angle)) * vars.radius) / Game.height
      vars.direction = {dx,dy}
    end
})

Entity("player", {
		animations = { "blue_robot" },
		animation = "blue_robot",
		net = true,
		align = "center",
		debug=true,
		t = 1,
		scale = 3,
		spawn = function(self)
			self.txt = Game.spawn("player_txt")
			self:setEffect('chroma shift2')
			self.effect:set('chroma shift2', 'radius', 4)
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
		
		print(badword.check("thesh!tmatwinkien"))
		Map.load("map0.map")
		Net.on('ready', function()	
			Game.spawn('player', {x=Game.width/2, y=Game.height/2}) -- Map.load("map0.map")	
		end)
		Net.connect()	
	end
})