math.randomseed(os.time())
local do_profiling = false -- false/#

local bitop = require 'lua.bitop'
local bit = bitop.bit
local bump = require "lua.bump"
uuid = require "lua.uuid"
json = require "lua.json"
class = require "lua.clasp"
callable = function(t) 
    if t.__ then 
        for _, mm in ipairs(t) do t['__'..mm] = t.__[mm] end 
    end
    return setmetatable(t, { __call = t.__call })
end
require "lua.print_r"
-- yes, plugins folder is listed twice
love.filesystem.setRequirePath('?.lua;?/init.lua;lua/?/init.lua;lua/?.lua;plugins/?/init.lua;plugins/?.lua;./plugins/?/init.lua;./plugins/?.lua')

-- is given version greater than or equal to current LoVE version?
local ge_version = function(major, minor, rev)
    if major and major > Game.love_version[1] then return false end
    if minor and minor > Game.love_version[2] then return false end 
    if rev and rev > Game.love_version[3] then return false end 
    return true
end

--UTIL.table
table.update = function (old_t, new_t, keys) 
    if keys == nil then
        for k, v in pairs(new_t) do 
            old_t[k] = v 
        end
    else
        for _,k in ipairs(keys) do if new_t[k] ~= nil then old_t[k] = new_t[k] end end
    end
    return old_t
end
table.keys = function (t) 
    ret = {}
    for k, v in pairs(t) do table.insert(ret,k) end
    return ret
end
table.every = function (t) 
    for k,v in pairs(t) do if not v then return false end end
    return true
end
table.some = function (t) 
    for k,v in pairs(t) do if v then return true end end
    return false
end
table.len = function (t) 
    c = 0
    for k,v in pairs(t) do c = c + 1 end
    return c
end
table.hasValue = function (t, val) 
    for k,v in pairs(t) do 
        if v == val then return true end
    end
    return false
end
table.slice = function (t, start, finish) 
    i, res, finish = 1, {}, finish or table.len(t)
    for j = start, finish do
        res[i] = t[j]
        i = i + 1
    end
    return res
end
table.defaults = function (t,defaults) 
    for k,v in pairs(defaults) do
        if t[k] == nil then t[k] = v 
        elseif type(v) == 'table' then table.defaults(t[k],defaults[k]) end
    end
end
table.append = function (t, new_t) 
    for k,v in pairs(new_t) do
        if type(k) == 'string' then t[k] = v
        else table.insert(t, v) end
    end
end
table.filter = function(t, fn)
    local len = table.len(t)
    local offset = 0
    for o = 1, len do 
        local element = t[o]
        if element then 
            if fn(element, o) then -- keep element
                t[o] = nil 
                t[o - offset] = element 
            else -- remove element
                t[o] = nil 
                offset = offset + 1
            end
        end
    end
end
table.random = function(t)
    return t[Math.random(1,#t)]
end
table.includes = function(t, v)
    for i = 1,#t do if t[i] == v then return true end end
    return false
end
table.join = function(t, sep)
    local str = ''
    for i = 1, #t do
        str = str .. tostring(t[i])
        if i ~= #t then 
            str = str .. tostring(sep)
        end
    end
    return str
end
--UTIL.string
function string:contains(q) 
    return string.match(tostring(self), tostring(q)) ~= nil
end
function string:capitalize() 
    return string.upper(string.sub(self,1,1))..string.sub(self,2)
end
function string:split(sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end
function string:replace(find, replace, wholeword)
    if wholeword then
        find = '%f[%a]'..find..'%f[%A]'
    end
    return (self:gsub(find,replace))
end
--math
local sin, cos, rad, deg, abs = math.sin, math.cos, math.rad, math.deg, math.abs
local floor = function(x) return math.floor(x+0.5) end
Math = {}
do
    for name, fn in pairs(math) do Math[name] = function(...) return fn(...) end end

    Math.sign = function(x) return (x < 0) and -1 or 1 end
    Math.seed = function(l,h) if l then love.math.setRandomSeed(l,h) else return love.math.getRandomSeed() end end
    Math.random = function(...) return love.math.random(...) end
    Math.indexTo2d = function(i, col) return math.floor((i-1)%col)+1, math.floor((i-1)/col)+1 end
    Math.getXY = function(angle, dist) return dist * cos(rad(angle)), dist * sin(rad(angle)) end
    Math.distance = function(x1,y1,x2,y2) return math.sqrt( (x2-x1)^2 + (y2-y1)^2 ) end
    Math.lerp = function(a,b,t) return a * (1-t) + b * t end
    Math.prel = function(a,b,v) -- returns what percent v is between a and b
        if v >= b then return 1 
        elseif v <= a then return 0 
        else return (v - a) / (b - a) end
    end
    Math.sinusoidal = function(min, max, spd, percent) return Math.lerp(min, max, Math.prel(-1, 1, math.cos(Math.lerp(0,math.pi/2,percent or 0) + (Game.time * spd))) ) end 
    --  return min + -math.cos(Math.lerp(0,math.pi/2,off or 0) + (Game.time * spd)) * ((max - min)/2) + ((max - min)/2) end
    Math.angle = function(x1, y1, x2, y2) return math.deg(math.atan2((y2-y1), (x2-x1))) end
    Math.pointInShape = function(shape, x, y)  
        local pts = {}
        for p = 1,#shape,2 do 
            table.insert(pts, {x=shape[p], y=shape[p+1]})
        end
        return PointWithinShape(pts,x,y)
    end

    function PointWithinShape(shape, tx, ty)
        if #shape == 0 then 
            return false
        elseif #shape == 1 then 
            return shape[1].x == tx and shape[1].y == ty
        elseif #shape == 2 then 
            return PointWithinLine(shape, tx, ty)
        else 
            return CrossingsMultiplyTest(shape, tx, ty)
        end
    end
     
    function BoundingBox(box, tx, ty)
        return	(box[2].x >= tx and box[2].y >= ty)
            and (box[1].x <= tx and box[1].y <= ty)
            or  (box[1].x >= tx and box[2].y >= ty)
            and (box[2].x <= tx and box[1].y <= ty)
    end
     
    function colinear(line, x, y, e)
        e = e or 0.1
        m = (line[2].y - line[1].y) / (line[2].x - line[1].x)
        local function f(x) return line[1].y + m*(x - line[1].x) end
        return math.abs(y - f(x)) <= e
    end
     
    function PointWithinLine(line, tx, ty, e)
        e = e or 0.66
        if BoundingBox(line, tx, ty) then
            return colinear(line, tx, ty, e)
        else
            return false
        end
    end
     
    -- from http://erich.realtimerendering.com/ptinpoly/ 
    function CrossingsMultiplyTest(pgon, tx, ty)
        local i, yflag0, yflag1, inside_flag
        local vtx0, vtx1
     
        local numverts = #pgon
     
        vtx0 = pgon[numverts]
        vtx1 = pgon[1]
     
        -- get test bit for above/below X axis
        yflag0 = ( vtx0.y >= ty )
        inside_flag = false
     
        for i=2,numverts+1 do
            yflag1 = ( vtx1.y >= ty )
     
            --[[ Check if endpoints straddle (are on opposite sides) of X axis
             * (i.e. the Y's differ); if so, +X ray could intersect this edge.
             * The old test also checked whether the endpoints are both to the
             * right or to the left of the test point.  However, given the faster
             * intersection point computation used below, this test was found to
             * be a break-even proposition for most polygons and a loser for
             * triangles (where 50% or more of the edges which survive this test
             * will cross quadrants and so have to have the X intersection computed
             * anyway).  I credit Joseph Samosky with inspiring me to try dropping
             * the "both left or both right" part of my code.
             --]]
            if ( yflag0 ~= yflag1 ) then
                --[[ Check intersection of pgon segment with +X ray.
                 * Note if >= point's X; if so, the ray hits it.
                 * The division operation is avoided for the ">=" test by checking
                 * the sign of the first vertex wrto the test point; idea inspired
                 * by Joseph Samosky's and Mark Haigh-Hutchinson's different
                 * polygon inclusion tests.
                 --]]
                if ( ((vtx1.y - ty) * (vtx0.x - vtx1.x) >= (vtx1.x - tx) * (vtx0.y - vtx1.y)) == yflag1 ) then
                    inside_flag =  not inside_flag
                end
            end
     
            -- Move to the next pair of vertices, retaining info as possible.
            yflag0  = yflag1
            vtx0    = vtx1
            vtx1    = pgon[i]
        end
     
        return  inside_flag
    end
     
    function GetIntersect( points )
        local g1 = points[1].x
        local h1 = points[1].y
     
        local g2 = points[2].x
        local h2 = points[2].y
     
        local i1 = points[3].x
        local j1 = points[3].y
     
        local i2 = points[4].x
        local j2 = points[4].y
     
        local xk = 0
        local yk = 0
     
        if checkIntersect({x=g1, y=h1}, {x=g2, y=h2}, {x=i1, y=j1}, {x=i2, y=j2}) then
            local a = h2-h1
            local b = (g2-g1)
            local v = ((h2-h1)*g1) - ((g2-g1)*h1)
     
            local d = i2-i1
            local c = (j2-j1)
            local w = ((j2-j1)*i1) - ((i2-i1)*j1)
     
            xk = (1/((a*d)-(b*c))) * ((d*v)-(b*w))
            yk = (-1/((a*d)-(b*c))) * ((a*w)-(c*v))
        end
        return xk, yk
    end
end
--UTIL.extra
switch = function(val, choices)
    if choices[val] then choices[val]()
    elseif choices.default then choices.default() end
end
-- for sorting a table of objects
sort = function(t, key) 
    table.sort(t, function(a, b) 
        if a == nil and b == nil then
            return false
        end
        if a == nil then
            return true
        end
        if b == nil then
            return false
        end
        if not a[key] then a[key] = 0 end 
        if not b[key] then b[key] = 0 end
        a['_last_'..key] = a[key]
        b['_last_'..key] = b[key]
        return a[key] < b[key]
    end)
end
copy = function(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local t_copy
    if orig_type == 'table' then
        if copies[orig] then
            t_copy = copies[orig]
        else
            t_copy = {}
            copies[orig] = t_copy
            for orig_key, orig_value in next, orig, nil do
                t_copy[copy(orig_key, copies)] = copy(orig_value, copies)
            end
            setmetatable(t_copy, copy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        t_copy = orig
    end
    return t_copy
end
is_object = function(o) return type(o) == 'table' and o.init and type(o.init) == 'function' end

encrypt = function(str, code, seed)
    local oldseed = {Math.seed()}
    if not seed then 
        seed = 0
        for c = 1, string.len(code) do 
            seed = seed + string.byte(string.sub(code,c,c))
        end 
    end 
    Math.seed(seed)
    local ret_str = ''
    local code_len = string.len(code)
    for c = 1, string.len(str) do
        ret_str = ret_str .. string.char(bit.bxor(string.byte(string.sub(str,c,c)), (c + Math.random(c,code_len)) % code_len))
    end
    Math.seed(unpack(oldseed))
    return ret_str
end
decrypt = function(str, code, seed)
    local oldseed = {Math.seed()}
    if not seed then 
        seed = 0
        for c = 1, string.len(code) do 
            seed = seed + string.byte(string.sub(code,c,c))
        end 
    end 
    Math.seed(seed)                                                                                                                                                                                                                                                         
    local ret_str = ''
    local code_len = string.len(code)
    for c = 1, string.len(str) do
        ret_str = ret_str .. string.char(bit.bxor(string.byte(string.sub(str,c,c)), (c + Math.random(c,code_len)) % code_len))
    end
    Math.seed(unpack(oldseed))                     
    return ret_str
end
lua_print = print 
do
    local str = ''
    local args
    print = function(...)
        str = ''
        args = {...}
        len = table.len(args)
        for i = 1,len do 
            str = str .. tostring(args[i] or 'nil') 
            if i ~= len then str = str .. ' ' end
        end
        lua_print(str)
    end
end

--CACHE
Cache = {}
do 
    local storage = {}
    Cache.group = function(name) return Cache[name] end
    Cache.key = function(group_name, key) return (Cache[group_name] and Cache[group_name][key]) end
    Cache.get = function(group_name, key, fn_not_found)
        if not storage[group_name] then storage[group_name] = {} end 
        if storage[group_name][key] then 
            return storage[group_name][key] 
        elseif fn_not_found then
            storage[group_name][key] = fn_not_found(key)
            return storage[group_name][key]
        end
    end
    Cache.stats = function()
        local str = '' 
        for name, list in pairs(storage) do 
            str = str .. name .. '=' .. table.len(list) .. ' '
        end
        print(str)
    end
end

--FS
FS = {
    basename = function (str)
        return string.gsub(str, "(.*/)(.*)", "%2")
    end,
    dirname = function (str)
        if string.match(str,".-/.-") then return string.gsub(str, "(.*/)(.*)", "%1") else return '' end
    end,
    extname = function (str)
        str = string.match(str,"^.+(%..+)$")
        if str then return string.sub(str,2) end
    end,
    removeExt = function (str)
        return string.gsub(str, '.'..FS.extname(str), '')
    end,
    ls = function (path)
        return love.filesystem.getDirectoryItems(path)
    end
}

--SIGNAL
Signal = nil
do
    local fns = {}
    Signal = {
        emit = function(event, ...)
            if fns[event] then 
                for _,fn in ipairs(fns[event]) do 
                    fn(...)
                end
            end
        end,
        on = function(event, fn) 
            if not fns[event] then fns[event] = {} end
            table.insert(fns[event], fn)
        end
    }
end

--INPUT
Input = nil
mouse_x, mouse_y = 0, 0
do
    local name_to_input = {} -- name -> { key1: t/f, mouse1: t/f }
    local input_to_name = {} -- key -> { name1, name2, ... }
    local options = {
        no_repeat = {},
        combo = {}
    }
    local pressed = {}
    local released = {}
    local key_assoc = {
        lalt='alt', ralt='alt',
        ['return']='enter', kpenter='enter',
        lgui='gui', rgui='gui'
    }
    Input = class {
        init = function(self, inputs, _options)
            for name, inputs in pairs(inputs) do
                Input.addInput(name, inputs)
            end
            if _options then
                table.append(options.combo, _options.combo or {})
                table.append(options.no_repeat, _options.no_repeat or {})
            end
            return nil
        end;

        addInput = function(name, inputs)
            name_to_input[name] = {}
            for _,i in ipairs(inputs) do name_to_input[name][i] = false end
            for _,i in ipairs(inputs) do
                if not input_to_name[i] then input_to_name[i] = {} end
                if not table.hasValue(input_to_name[i], name) then table.insert(input_to_name[i], name) end
            end
        end;

        pressed = function(name) if not (table.hasValue(options.no_repeat, name) and pressed[name] and pressed[name].count > 1) then return pressed[name] end end;

        released = function(name) return released[name] end;

        press = function(key, extra)
            if key_assoc[key] then Input.press(key_assoc[key], extra) end
            if input_to_name[key] then
                for _,name in ipairs(input_to_name[key]) do
                    local n2i = name_to_input[name]
                    if not n2i then name_to_input[name] = {} end
                    n2i = name_to_input[name]
                    n2i[key] = true
                    -- is input pressed now?
                    combo = table.hasValue(options.combo, name)
                    if (combo and table.every(n2i)) or (not combo and table.some(n2i)) then
                        pressed[name] = extra
                        pressed[name].count = 1
                    end
                end
            end
        end;

        release = function(key, extra)
            if key_assoc[key] then Input.release(key_assoc[key], extra) end
            if input_to_name[key] then
                for _,name in ipairs(input_to_name[key]) do
                    local n2i = name_to_input[name]
                    if not n2i then name_to_input[name] = {} end
                    n2i = name_to_input[name]
                    n2i[key] = false
                    -- is input released now?
                    combo = table.hasValue(options.combo, name)
                    if pressed[name] and (combo or not table.some(n2i)) then
                        pressed[name] = nil
                        released[name] = extra
                    end
                end
            end
        end;
        
        keyCheck = function() 
            for name, info in pairs(pressed) do
                info.count = info.count + 1
            end
            released = {}
        end;

        -- mousePos = function() return love.mouse.getPosition() end;
    }
end

--CANVASSTACK
CanvasStack = nil
do 
    local stack = {} -- { }
    CanvasStack = class{
        getCanvas = function(self)
            if not self.canvas then 
                local found = false 
                -- recycle a canvas
                for c, canv in ipairs(stack) do 
                    if not canv._used then 
                        self.canvas = canv
                        found = true
                    end 
                end 
                -- add a new canvas
                if not found then 
                    self.canvas = Canvas()
                    self.canvas:remDrawable()
                    table.insert(stack, self.canvas)
                end
                self.canvas._used = true
            end
            return self.canvas
        end,
        drawTo = function(self, fn)
            self.canvas:drawTo(fn)
        end,
        draw = function(self)   
            if self.quad then self.canvas.quad = self.quad end  
            self.canvas:draw()  
        end,
        release = function(self)
            self.canvas._used = false
            self.canvas:reset()
            self.canvas = nil
        end
    }
end

--DRAW
Draw = nil 
do
    local _hex_cache = {}
    local _hex2rgb = function(hex)
        assert(type(hex) == "string", "hex2rgb: expected string, got "..type(hex).." ("..hex..")")
        hex = hex:gsub("#","")
        if(string.len(hex) == 3) then
            return {tonumber("0x"..hex:sub(1,1)) * 17 / 255, tonumber("0x"..hex:sub(2,2)) * 17 / 255, tonumber("0x"..hex:sub(3,3)) * 17 / 255}
        elseif(string.len(hex) == 6) then
            return {tonumber("0x"..hex:sub(1,2)) / 255, tonumber("0x"..hex:sub(3,4)) / 255, tonumber("0x"..hex:sub(5,6)) / 255}
        end
    end

    local fonts = {} -- { 'path+size': font }
    local getFont = function(path, size)
        size = size or 12
        local key = path..'+'..size
        if fonts[key] then return fonts[key] end 
        local font = love.graphics.newFont(path, size)
        fonts[key] = font 
        return font
    end  
    local DEF_FONT = "04B_03.ttf"
    local last_font
    Draw = class {
        crop_used = false;
        init = function(self, instructions)
            for _,instr in ipairs(instructions) do
                name, args = instr[1], table.slice(instr,2)
                assert(Draw[name], "bad draw instruction '"..name.."'")
                Draw[name](unpack(args))
            end
        end;
        setFont = function(path, size)
            path = path or last_font or DEF_FONT
            last_font = path
            if path ~= DEF_FONT then path = Game.res('font', path) end
            local font = getFont(path, size)
            assert(font, 'Font not found: \''..path..'\'')
            love.graphics.setFont(font)
        end;
        getFont = function() return love.graphics.getFont() end;
        setFontSize = function(size)
            Draw.setFont(last_font, size)
        end;
        addImageFont = function(path, glyphs, ...)
            path = Game.res('image', path)
            if fonts[path] then return fonts[path] end 
            local font = love.graphics.newImageFont(path, glphs, ...)
            fonts[path] = font 
            return font
        end;
        setImageFont = function(path)
            path = Game.res('image', path)
            local font = fonts[path]
            assert(font, "ImageFont not found: \'"..path.."\'")
            love.graphics.setFont(font)
        end;
        print = function(txt,x,y,char_limit,align,...)
            if not char_limit then 
                char_limit = Draw.getFont():getWidth(txt)
            end
            love.graphics.printf(txt,x,y,char_limit,align,...)
        end;
        parseColor = function(...)
            args = {...}
            if #args == 0 then return 0, 0, 0, 1 end
            local c = Color[args[1]]
            if c then 
                args = {c[1],c[2],c[3],args[2] or 1}
                for a,arg in ipairs(args) do 
                    if arg > 1 then args[a] = arg / 255 end
                end
            end
            if #args == 0 then args = {1,1,1,1} end
            if not args[4] then args[4] = 1 end
            return args[1], args[2], args[3], args[4]
        end;
        color = function(...)
            return love.graphics.setColor(Draw.parseColor(...))
        end;
        hexToRgb = function(hex) 
            if _hex_cache[hex] then return _hex_cache[hex] end
            local ret = _hex2rgb(hex)
            _hex_cache[hex] = ret 
            return ret
        end;
        getBlendMode = function() return love.graphics.getBlendMode() end;
        setBlendMode = function(...) love.graphics.setBlendMode(...) end;
        crop = function(x,y,w,h)
            love.graphics.setScissor(x,y,w,h)
            -- stencilFn = () -> Draw.rect('fill',x,y,w,h)
            -- love.graphics.stencil(stencilFn,"replace",1)
            -- love.graphics.setStencilTest("greater",0)
            -- Draw.crop_used = true
        end;
        rotate = function(r)
            love.graphics.rotate(math.rad(r))
        end;
        translate = function(x,y)
            love.graphics.translate(floor(x), floor(y))
        end;
        reset = function(only)
            if only == 'color' or not only then
                Draw.color(1,1,1,1)
                Draw.lineWidth(1)
            end
            if only == 'transform' or not only then
                Draw.origin()
            end
            if (only == 'crop' or not only) and Draw.crop_used then
                Draw.crop_used = false
                love.graphics.setStencilTest()
            end
        end;
        push = function() love.graphics.push('all') end;
        pop = function()
            Draw.reset('crop')
            love.graphics.pop()
        end;
        stack = function(fn)
            Draw.push()
            fn()
            Draw.pop()
        end;
        newTransform = function()
            return love.math.newTransform()
        end;
        clear = function(...)
            love.graphics.clear(Draw.parseColor(...))
        end
    }
    
    local draw_functions = {
        'arc','circle','ellipse','line','points','polygon','rectangle',--'print','printf',
        'discard','origin',
        'scale','shear','transformPoint',
        'setLineWidth','setPointSize',
        'applyTransform', 'replaceTransform'
    }
    local draw_aliases = {
        polygon = 'poly',
        rectangle = 'rect',
        setLineWidth = 'lineWidth',
        setPointSize = 'pointSize',
        points = 'point',
        setFont = 'font',
        setFontSize = 'fontSize'
    }
    for _,fn in ipairs(draw_functions) do 
        Draw[fn] = function(...) return love.graphics[fn](...) end 
    end
    for old, new in pairs(draw_aliases) do
        Draw[new] = Draw[old]
    end
end

Color = {
    red =        {244,67,54},
    pink =       {240,98,146},
    purple =     {156,39,176},
    deeppurple = {103,58,183},
    indigo =     {63,81,181},
    blue =       {33,150,243},
    lightblue =  {3,169,244},
    cyan =       {0,188,212},
    teal =       {0,150,136},
    green =      {76,175,80},
    lightgreen = {139,195,74},
    lime =       {205,220,57},
    yellow =     {255,235,59},
    amber =      {255,193,7},
    orange =     {255,152,0},
    deeporange = {255,87,34},
    brown =      {121,85,72},
    grey =       {158,158,158},
    gray =       {158,158,158},
    bluegray =   {96,125,139},
    white =      {255,255,255},
    white2 =     {250,250,250},
    black =      {0,0,0},
    black2 =     {33,33,33}
}

--WINDOW
Window = {}
do 
    local pre_fs_size = {}
    local last_win_size = {0,0}
    local setMode = function(w,h,flags)
        if not (not flags and last_win_size[1] == w and last_win_size[2] == h) then
            love.window.setMode(w, h, flags or Game.options.window_flags)
        end
    end
    Window = {
        os = '?';
        aspect_ratio = nil;
        aspect_ratios = { {4,3}, {5,4}, {16,10}, {16,9} };
        resolutions = { 512, 640, 800, 1024, 1280, 1366, 1920 };
        aspectRatio = function()
            local w, h = love.window.getDesktopDimensions()
            for _,ratio in ipairs(Window.aspect_ratios) do
                if w * (ratio[2] / ratio[1]) == h then
                    Window.aspect_ratio = ratio
                    return ratio
                end
            end
        end;
        vsync = function(v)
            if not ge_version(11,3) then return end
            if not v then return love.window.getVSync()
            else love.window.setVSync(v) end
        end;
        setSize = function(r, flags)
            local w, h = Window.calculateSize(r)
            setMode(w,h,flags)
        end;
        setExactSize = function(w, h, flags)
            setMode(w,h,falgs)
        end;
        calculateSize = function(r)
            r = r or Game.config.window_size
            if not Window.aspect_ratio then Window.aspectRatio() end
            local w = Window.resolutions[r]
            local h = w / Window.aspect_ratio[1] * Window.aspect_ratio[2]
            return w, h
        end;
        fullscreen = function(v,fs_type)
            local res
            if v == nil then 
                res = love.window.getFullscreen()
            else 
                res = love.window.setFullscreen(v,fs_type)
            end
            Game.updateWinSize(unpack(pre_fs_size)) 
            return res
        end;
        toggleFullscreen = function()
            if not Window.fullscreen() then
                pre_fs_size = {Game.width, Game.height}
            end
            local res = Window.fullscreen(not Window.fullscreen())
            if res then
                if not Window.fullscreen() then 
                    Window.setExactSize(unpack(pre_fs_size))
                end
            end
            return res
        end
    }
end

--GAME
Game = callable{
    options = {
        persistent =    true,
        res =           'assets',
        scripts =       {},
        filter =        'linear',
        vsync =         1,
        auto_require =  true,
        background_color = 'black',
        window_flags = {},
        load = function() end,
        draw =          function() end,
        postdraw =      nil,
        update = function(dt) end,
        canvas = { }
    },
    __call = function(_, options)
        table.update(Game.options, options or {})
        Game.options.persistent = true
        World.add(Game.options)

        -- load config.json
        config_data = love.filesystem.read('config.json')
        if config_data then Game.config = json.decode(config_data) end
        table.update(Game.options, Game.config.export)
        -- get current os
        Window.os = ({ ["OS X"]="mac", ["Windows"]="win", ["Linux"]="linux", ["Android"]="android", ["iOS"]="ios" })[love.system.getOS()]-- Game.options.os or 'ide'
        Window.full_os = love.system.getOS()
        -- load settings
        Game.width, Game.height = Window.calculateSize(Game.config.game_size) -- game size
        -- window size and flags
        Game.options.window_flags = table.update({
            borderless = Game.options.frameless,
            resizable = Game.options.resizable,
        }, Game.options.window_flags or {})

        Window.setSize(Game.config.window_size)
        Game.updateWinSize()
        -- vsync
        switch(Game.options.vsync, {
            on = function() Window.vsync(1) end,
            off = function() Window.vsync(0) end,
            adaptive = function() Window.vsync(-1) end
        })

        if type(Game.options.filter) == 'table' then
            love.graphics.setDefaultFilter(unpack(Game.options.filter))
        else 
            love.graphics.setDefaultFilter(Game.options.filter, Game.options.filter)
        end
        Draw.setFont('04B_03.ttf', 16)
        scripts = Game.options.scripts or {}
        -- load plugins
        if Game.options.plugins then 
            for _,f in ipairs(Game.options.plugins) do 
                table.insert(scripts,'plugins.'..f)
            end
        end
        -- load scripts
        if Game.options.auto_require then
            files = FS.ls ''
            for _,f in ipairs(files) do
                print(f)
                if FS.extname(f) == 'lua' and not table.hasValue(scripts, f) then
                    new_f = FS.removeExt(f)
                    table.insert(scripts, new_f)
                end
            end
        end
        for _,script in ipairs(scripts) do
            if script ~= 'main' then 
                Game.require(script)
            end
        end
        -- fullscreen toggle
        Input({ _fs_toggle = { 'alt', 'enter' } }, { 
            combo = { '_fs_toggle' },
            no_repeat = { '_fs_toggle' },
        })

        love.graphics.setBackgroundColor(0,0,0,0)
    end,

    updateWinSize = function(w,h)
        Game.win_width, Game.win_height, flags = love.window.getMode()
        if w and h then Game.win_width, Game.win_height = w, h end
        if not Game.options.scale then
            Game.width, Game.height = Game.win_width, Game.win_height
            Game.options.canvas.size = {Game.width, Game.height}
        end
    end,
    
    res = function(_type, file)
        return Game.options.res.."/".._type.."/"..file
    end, 

    require = function(path)
        return require(path) 
    end
}
