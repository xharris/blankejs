BlankE.addState("TestState");

local img_penguin, img_sheet
local my_eff

function TestState:enter()
	Draw.setBackgroundColor('white')
	img_penguin = Image("Basic Bird")
	img_sheet = Image("sprite-example")

	Effect.new{
		name="outline",
		params={size=1, color={1,0,0,1}},
		effect=[[
			float incr = getX(1.0);
			float max = getX(size);
			
			vec4 pixel_l, pixel_r, pixel_u, pixel_d, pixel_lu, pixel_ru, pixel_ld, pixel_rd;
			for (float s = 0; s < max; s += incr) {
				pixel_l = Texel(texture, vec2(texCoord.x-s, texCoord.y));
				pixel_r = Texel(texture, vec2(texCoord.x+s, texCoord.y));
				pixel_u = Texel(texture, vec2(texCoord.x, texCoord.y-s));
				pixel_d = Texel(texture, vec2(texCoord.x, texCoord.y+s));
		
				pixel_lu = Texel(texture, vec2(texCoord.x-s, texCoord.y-s));
				pixel_ru = Texel(texture, vec2(texCoord.x-s, texCoord.y+s));
				pixel_ld = Texel(texture, vec2(texCoord.x+s, texCoord.y-s));
				pixel_rd = Texel(texture, vec2(texCoord.x+s, texCoord.y+s));

				if (pixel.a == 0 && (pixel_l.a > 0 || pixel_r.a > 0 || pixel_u.a > 0 || pixel_d.a > 0 || pixel_lu.a > 0 || pixel_ru.a > 0 || pixel_ld.a > 0 || pixel_rd.a > 0)) 
					pixel = color;
			}
		]]
	}
	my_eff = Effect("static")
end

function TestState:update(dt)

end


local x, y = game_width/2, game_height/2
local my_mario = Mario()
my_mario.x = 0
my_mario.y = 0
local my_luigi = Mario()
local my_view = View(my_mario)

function TestState:draw()
	Draw.setColor("red")
	Draw.reset("color")
		
	my_view:draw(function()	
		my_eff:draw(function()
			img_penguin.x = game_width / 2
			img_penguin.y = game_height / 2
			img_penguin:draw()

			my_luigi.x = 0
			my_luigi.y = 0
			my_luigi:draw()

			Draw.setColor("blue")
			Draw.circle("line",my_mario.x,my_mario.y,50)
			Draw.reset("color")

		end)	
      	my_mario:draw()
	end)
end
