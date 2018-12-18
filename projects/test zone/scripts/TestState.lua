BlankE.addState("TestState");

local img_penguin, img_sheet
local my_eff

function TestState:enter()
	img_penguin = Image("Basic Bird")
	img_sheet = Image("sprite-example")

	Effect.new{
		name="outline",
		params={size=1},
		effect=[[
			float incr = 1.0 / love_ScreenSize.x;
			float max = size / love_ScreenSize.x;
			
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
					pixel = vec4(1,0,0,1);
			}
		]]
	}
	my_eff = Effect("outline")
end

function TestState:update(dt)

end

function TestState:draw()
	my_eff.size = (mouse_x / game_width) * 20;
	
	Draw.setColor("red")
	Draw.text(my_eff.size, 50, 50)
	Draw.reset("color")
	
	my_eff:draw(function()
		img_penguin.x = game_width / 2
		img_penguin.y = game_height / 2
		img_penguin:draw()
			
		Draw.setColor("blue")
		Draw.circle("line",100,100,50)
		Draw.reset("color")
	end)
end
