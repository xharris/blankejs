Draw = Class{
	font = nil,
	--[[Font{
		size=20,
		align="center"
	},]]
	background_color = {0,0,0,1},
	color = {0,0,0,255},
	reset_color = {1,1,1,1},

	colors = {'red','pink','purple','indigo','baby_blue','blue',
			  'dark_blue','green','yellow','orange','brown',
			  'gra/ey','black','white','black2','white2'},
	red = {244,67,54,255},
	pink = {233,30,99,255},
	purple = {103,58,183,255},
	indigo = {63,81,181,255},
	baby_blue = {128,216,255,255},
	blue = {33,150,243,255},
	dark_blue = {13,71,161,255},
	green = {76,175,80,255},
	yellow = {255,235,59,255},
	orange = {255,193,7,255},
	brown = {121,85,72,255},
	gray = {158,158,158,255},
	grey = {158,158,158,255},
	black = {0,0,0,255},
	white = {255,255,255,255},
	black2 = {33,33,33,255},	-- but not actually black
	white2 = {245,245,245,255},	-- but not actually white

	_parseColorArgs = function(r,g,b,a)
		color = r
        
		if (type(color) == "table") then
			r, g, b, a = unpack(color)
		end
		if (type(color) == "string") and color:startsWith("#") then
			color = hex2rgb(color)
		elseif (type(color) == "string") then
			color = Draw[color]
			if color then
				if g then color[4] = clamp(g, 0, 255)
				else color[4] = 255 end
			end
		end
		if (type(color) == "number") then
			color = {r,g,b,a}
		end
        if color == nil then
            color = Draw.white
        end
        
		for v, val in ipairs(color) do
			if val > 1 then color[v] = val / 255 end
		end

		return color
	end,

	setBackgroundColor = function(r,g,b,a)
		Draw.background_color = Draw._parseColorArgs(r,g,b,a)
		love.graphics.setBackgroundColor(Draw.background_color)
		return Draw
	end,

	randomColor = function(alpha)
		return {randRange(0,255)/255, randRange(0,255)/255, randRange(0,255)/255, ifndef(alpha, 1)}
	end,

	invertColor = function(r,g,b,a)
		local color = Draw._parseColorArgs(r,g,b,a)
		return {1 - color[1], 1 - color[2], 1 - color[3], a}
	end,

	setColor = function(r,g,b,a)
		if r == nil then BlankE.errhand("invalid color: {"..tostring(r)..", "..tostring(g)..", "..tostring(b)..", "..tostring(a).."}"); return false end
        
		Draw.color = Draw._parseColorArgs(r,g,b,a)
		if Draw.color then
			love.graphics.setColor(Draw._parseColorArgs(r,g,b,a))
		end
		return Draw
	end,

	setAlpha = function(a)
		a = clamp(a,0,255)
		if a > 1 then a = a / 255 end
		Draw.color[4] = a
		if Draw.color then
			love.graphics.setColor(Draw.color)
		end
		return Draw
	end,

	setPointSize = function(size)
		love.graphics.setPointSize(size)
	end,
	
	translate = function(x, y)
		love.graphics.translate(x, y)
	end,

	scale = function(x_scale, y_scale)
		love.graphics.scale(x_scale, ifndef(y_scale, x_scale))
	end,

	shear = function(x, y)
		love.graphics.shear(x,y)
	end,

	-- degrees
	rotate = function(deg)
		love.graphics.rotate(math.rad(deg))
	end,

	crop_used = false,
	crop = function(x,y,w,h)
		local function stencilFn()
			love.graphics.rectangle("fill",x,y,w,h)
		end
		love.graphics.stencil(stencilFn, "replace",1)
		love.graphics.setStencilTest("greater",0)
		Draw.crop_used = true
	end,	

	reset = function(only)
    	if only == "color" or not only then 
			Draw.color = Draw.reset_color
			Draw.setColor(Draw.color)
		end 
		if only == "transform" or not only then
			love.graphics.origin()
		end
		if (only == "crop" or not only) and Draw.crop_used then
    		Draw.crop_used = false
    		love.graphics.setStencilTest()
		end
	end,
    
    callDrawFunc = function(shape, args)
		--Draw.stack(function()
			love.graphics[shape](unpack(args))
		--end)
		return Draw
    end,

    stack = function(fn)
    	Draw.push('all')
    	fn()
    	Draw.pop()
    end,

    push = function()
    	love.graphics.push('all')
    end,

    pop = function()
    	Draw.reset("crop")
    	love.graphics.pop()
    end,

    setFont = function(new_font)
    	if type(new_font) == "string" and Asset.has('font', new_font) then
    		Draw.font = Asset.get('font', new_font)
    	elseif type(new_font) == 'table' then
    		Draw.font = new_font
    	else
    		Draw.font = new_font
    	end 
    end,

    setLineWidth = love.graphics.setLineWidth,
    setPointSize = love.graphics.setPointSize,
    
    point   = function(...) return Draw.callDrawFunc('points', {...}) end, 	-- point was removed in 10.0
    points 	= function(...) return Draw.callDrawFunc('points', {...}) end,
    line 	= function(...) return Draw.callDrawFunc('line', {...}) end,
    rect 	= function(...) return Draw.callDrawFunc('rectangle', {...}) end,
    circle 	= function(...) return Draw.callDrawFunc('circle', {...}) end,
    polygon = function(...) return Draw.callDrawFunc('polygon', {...}) end,
    text 	= function(text, x, y, ...) 
    	if Draw.font then
			return Draw.font:draw(text, x, y, ...)--love.graphics.setFont(Draw.font)
		else
			return Draw.callDrawFunc('print', {text, x, y, ...})
		end
    end,
    textf 	= function(text, x, y, ...)
    	if Draw.font then
			return Draw.font:draw(text, x, y, ...)--love.graphics.setFont(Draw.font)
		else
			return Draw.callDrawFunc('printf', {text, x, y, ...})
		end
    end,
}

--love.graphics.setLineStyle("rough")

return Draw