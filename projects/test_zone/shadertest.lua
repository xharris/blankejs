State("shadertest",{
	enter = function()
		Game.setBackgroundColor('black2')
		for i = 1, 2 do 
			Game.spawn("sprite", {x=(i*10) + 20, y = Game.height/2})
		end
	end
})

		
Entity("sprite",{
	animations = { "blue_robot" },
	animation = "blue_robot",
	align = "center",
	effect = { 'grayscale', 'chroma shift' },
	my_uncle = { "uncle" },
	update = function(self, dt)
		self.my_uncle.x = self.x
		self.my_uncle.y = self.y
		--self.y = (Game.height/2) + (Math.sinusoidal(-1,1,4,self.x/Game.width) * 100)
		
		self.effect:disable("grayscale")
		self.effect:set('chroma shift','radius',(mouse_x/Game.width)*20)
	end
})
		
Entity("uncle",{
		--effect = { 'grayscale' }, -- TODO test chroma shift
	draw = function(self)
		Draw{
			{ 'color', 'red' },
			{ 'rotate', 45 },
			{ 'print', math.floor(self.y), 50,40}
		}
	end
})