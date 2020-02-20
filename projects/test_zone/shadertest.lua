local i = 0
local spawn = function()
	i = i + 1
	Game.spawn("sprite", {x=(i*10) + (Game.width/2), y = Game.height/2})
end


State("shadertest",{
	enter = function()
		Input({
			new_ent = { 'mouse1' }
		})
		
		Game.setBackgroundColor('white2')
		spawn()
	end,
	update = function(dt)
		if Input.released('new_ent') then 
			spawn()
		end
	end
})

		
Entity("sprite",{
	animations = { "blue_robot" },
	animation = "blue_robot",
	align = "center",
	effect = { 'bloom' },
	my_uncle = { "uncle" },
	scale = 2,
	update = function(self, dt)
		self.my_uncle.x = self.x
		self.my_uncle.y = self.y
		--self.y = (Game.height/2) + (Math.sinusoidal(-1,1,4,self.x/Game.width) * 100)
		
		--self.effect:set('chroma shift','radius',(mouse_x/Game.width)*20)
	end,
	predraw = function(self)
		Draw{
			{'color','black2'},
			{'circle','fill',0,-30,15},
		}
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