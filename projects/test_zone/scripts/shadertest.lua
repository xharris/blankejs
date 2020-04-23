local i = 0
local spawn = function()
	i = i + 1
	Game.spawn("sprite", {x=(i*10) + (Game.width/2), y = Game.height/2})
end

local img = Image('megman.png')

Effect.new('static2', {
  vars = { strength={5,0} },
  effect = [[
	number amt = 50.0;
  vec2 new_tc = texture_coords - vec2(mod(texture_coords.x, amt), mod(texture_coords.y, amt));
  pixel = Texel(texture, new_tc);
  return pixel * color;
  number off = random(vec2(0, 1.0), new_tc, time);
  pixel = Texel(texture, vec2(
			texture_coords.x + getX(off - 1.0) * strength.x,
			texture_coords.y + getY(off - 1.0) * strength.y
		));
  ]]
})

State("shadertest",{
	enter = function()
		Input({
			new_ent = { 'mouse1' }
		})
		
		Game.setBackgroundColor('white2')
		spawn()
		img:setEffect("static2")
	end,
	update = function(dt)
		if Input.released('new_ent') then 
			spawn()
		end
		-- img.effect:set('chroma shift','radius',(mouse_x/Game.width)*20)
	end,
	draw = function()
		img:draw()
	end
})

		
Entity("sprite",{
	animations = { "blue_robot" },
	animation = "blue_robot",
	align = "center",
	--effect = { 'static2', 'chroma shift' },
	my_uncle = { "uncle" },
	scale = 2,
	update = function(self, dt)
		self.my_uncle.x = self.x
		self.my_uncle.y = self.y
		--self.y = (Game.height/2) + (Math.sinusoidal(-1,1,4,self.x/Game.width) * 100)
		
		--self.effect:disable('chroma shift')
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