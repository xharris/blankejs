Draw = Class{
	font = nil,

	background_color = {0,0,0,1},
	color = {0,0,0,255},
	reset_color = {255,255,255,255},

	colors = {'red','pink','purple','indigo','baby_blue','blue',
			  'dark_blue','green','yellow','orange','brown',
			  'gray/grey','black','white','black2','white2'},
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
	transparent = {0,0,0,0},

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
		if r == nil then error("invalid color: {"..tostring(r)..", "..tostring(g)..", "..tostring(b)..", "..tostring(a).."}"); return false end
        
		Draw.color = Draw._parseColorArgs(r,g,b,a)
		if Draw.color then
			love.graphics.setColor(Draw._parseColorArgs(r,g,b,a))
		end
		return Draw
	end,

	getColor = love.graphics.getColor,

	setAlpha = function(a)
		a = clamp(a,0,255)
		if a > 1 then a = a / 255 end
		Draw.color[4] = a
		if Draw.color then
			love.graphics.setColor(Draw.color)
		end
		return Draw
	end,

	setDefaultFilter = function(min,mag,ani)
		love.graphics.setDefaultFilter(min,mag,ani)
		BlankE.game_canvas:setFilter(min,mag,ani)
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
			Draw.setColor("white")
			Draw.setLineWidth(1)
		end 
		if only == "transform" or not only then
			Draw.origin()
		end
		if (only == "crop" or not only) and Draw.crop_used then
    		Draw.crop_used = false
    		love.graphics.setStencilTest()
		end
	end,

	origin = love.graphics.origin,
    
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

    grid = function(rows, columns, h_spacing, v_spacing, func)
    	for x = 0, columns - 1 do
    		for y = 0, rows - 1 do
    			func(x * h_spacing, y * v_spacing, x+1, y+1)
    		end
    	end
    end,

    setFont = function(new_font)
    	if type(new_font) == "number" or new_font == nil then
    		Draw.font = Font{name="console",size=(new_font or 12)}
    	elseif type(new_font) == "string" and Asset.has('font', new_font) then
    		Draw.font = Font{name=new_font}
    	elseif type(new_font) == 'table' then
    		if new_font.classname == "Font" then
    			Draw.font = new_font
    		else
    			Draw.font = Font(new_font)
    		end
    	else
    		error("Incorrect Font: '"..tostring(new_font).."'")
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
    text 	= function(text, x, y, options) 
    	local opt = options or {}
    	if Draw.font then
    		Draw.font:use()
		end 

		return Draw.callDrawFunc('printf', {text, x or 0, y or 0, opt.max_x or game_width, opt.align or "left", math.rad(opt.angle or 0), 
			opt.scale_x or 1, opt.scale_y or 1, opt.offset_x or 0, opt.offset_y or 0, opt.shear_x or 0, opt.shear_y or 0})
    end
}

--love.graphics.setLineStyle("rough")
Draw["gray/grey"] = {158,158,158,255}

return Draw