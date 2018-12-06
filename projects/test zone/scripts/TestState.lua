BlankE.addState("TestState");

local img_penguin
local my_eff

function TestState:enter()
	img_penguin = Image("Basic Bird")
	Effect.new{
		name="outline",
		params={size=0.1},
		effect=[[
			vec4 pixel_l = Texel(texture, vec2(texCoord.x-size, texCoord.y));
			vec4 pixel_r = Texel(texture, vec2(texCoord.x+size, texCoord.y));
			vec4 pixel_u = Texel(texture, vec2(texCoord.x, texCoord.y-size));
			vec4 pixel_d = Texel(texture, vec2(texCoord.x, texCoord.y+size));
		
			
			if (pixel.a == 0 && (pixel_l.a > 0 || pixel_r.a > 0 || pixel_u.a > 0 || pixel_d.a > 0)) 
				pixel = vec4(1,0,0,1);
			
		]]
	}
	my_eff = Effect("outline")
end

function TestState:update(dt)

end

function TestState:draw()
	Draw.setColor("red")
	Draw.text(mouse_x / game_width, 50, 50)
	Draw.reset("color")
	
	my_eff:send('size',mouse_x / game_width)
	my_eff:draw(function()
		img_penguin.x = game_width / 2
		img_penguin.y = game_height / 2
		img_penguin:draw()
	end)
end
