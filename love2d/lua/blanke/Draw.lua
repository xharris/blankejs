Draw = Class{
	color = {0,0,0,255},
	reset_color = {255,255,255,255},

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
	black = {0,0,0,255},
	white = {255,255,255,255},
	black2 = {33,33,33,255},	-- but not actually black
	white2 = {245,245,245,255},	-- but not actually white

	_parseColorArgs = function(r,g,b,a)
		color = r

		if (type(color) == "string") and color:startsWith("#") then
			color = hex2rgb(color)
		elseif (type(color) == "string") then
			color = Draw[color]
		end
		if (type(color) == "number") then
			color = {r,g,b,a}
		end
		return color
	end,

	setBackgroundColor = function(r,g,b,a)
		love.graphics.setBackgroundColor(Draw._parseColorArgs(r,g,b,a))
		return Draw
	end,

	randomColor = function(alpha)
		return {randRange(0,255), randRange(0,255), randRange(0,255), ifndef(alpha, 255)}
	end,

	setColor = function(r,g,b,a)
		if r == nil then BlankE.errhand("invalid color: {"..tostring(r)..", "..tostring(g)..", "..tostring(b)..", "..tostring(a).."}"); return false end

		if (type(r) == "table") then
			r, g, b, a = unpack(r)
		end
		Draw.color = Draw._parseColorArgs(r,g,b,a)
		love.graphics.setColor(Draw.color)
		return Draw
	end,

	translate = function(x, y)
		love.graphics.translate(x, y)
	end,

	scale = function(x_scale, y_scale)
		love.graphics.scale(x_scale, ifndef(y_scale, x_scale))
	end,

	reset = function(dont_scale)
		love.graphics.origin()
		if not dont_scale then BlankE.reapplyScaling() end
	end,

	resetColor = function()
		Draw.color = Draw.reset_color
		return Draw
	end,

	_draw = function(func)
		love.graphics.push('all')
		func()
		love.graphics.pop()
		return Draw
	end,
    
    callDrawFunc = function(shape, args)
		Draw._draw(function()
			love.graphics[shape](unpack(args))
		end)
		return Draw
    end,

    push = function(...)
    	love.graphics.push(...)
    end,

    pop = function()
    	love.graphics.pop()
    end,

    setLineWidth = love.graphics.setLineWidth,
    
    point   = function(...) return Draw.callDrawFunc('points', {...}) end,
    points 	= function(...) return Draw.callDrawFunc('points', {...}) end,
    line 	= function(...) return Draw.callDrawFunc('line', {...}) end,
    rect 	= function(...) return Draw.callDrawFunc('rectangle', {...}) end,
    circle 	= function(...) return Draw.callDrawFunc('circle', {...}) end,
    polygon = function(...) return Draw.callDrawFunc('polygon', {...}) end,
    text 	= function(...) return Draw.callDrawFunc('print', {...}) end,
    textf 	= function(...) return Draw.callDrawFunc('printf', {...}) end,
}

return Draw