-- TODO Images have their own hitbox instead of entity. Entity just uses the current animations hitbox
-- TODO rework Image to autobatch
-- TODO Blanke.config
local _NAME = ...
local blanke_require = function(r)
    return require(r)
end

math.randomseed(os.time())
local do_profiling = nil -- false/#
local profiling_color = {1,0,0,1}

local gobject_count = {}

local bitop = blanke_require('bitop')
local bit = bitop.bit
local bump = blanke_require("bump")
uuid = blanke_require("uuid")
json = blanke_require("json")
class = blanke_require("clasp")
blanke_require("noobhub")
blanke_require("print_r")

local socket = blanke_require("socket")
callable = function(t) 
    if t.__ then 
        for _, mm in ipairs(t) do t['__'..mm] = t.__[mm] end 
    end
    return setmetatable(t, { __call = t.__call })
end
-- yes, plugins folder is listed twice
--love.filesystem.setRequirePath('?.lua;?/init.lua;lua/?/init.lua;lua/?.lua;plugins/?/init.lua;plugins/?.lua;./plugins/?/init.lua;./plugins/?.lua')

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
    return t
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
local sin, cos, rad, deg, abs, min, max = math.sin, math.cos, math.rad, math.deg, math.abs, math.min, math.max
local floor = function(x) return math.floor(x+0.5) end
Math = {}
do
    for name, fn in pairs(math) do Math[name] = function(...) return fn(...) end end

    Math.clamp = function(x, _min, _max) return min(_max, max(_min, x)) end
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
    Math.sinusoidal = function(min, max, spd, percent) return Math.lerp(min, max, Math.prel(-1, 1, math.cos(Math.lerp(0,math.pi/2,percent or 0) + (Game.time * (spd or 1)) )) ) end 
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
sort = function(t, key, default) 
    table.sort(t, function(a, b) 
        if a[key] == nil then a[key] = default end 
        if b[key] == nil then b[key] = default end
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

--STACK
Stack = class{
    init = function(self, fn_new)
        self.stack = {} -- { { used:t/f, value:?, is_stack:true, release:fn() } }
        self.fn_new = fn_new
    end,
    new = function(self, remake)
        local found = false
        for _, s in ipairs(self.stack) do 
            if not s.used then 
                found = true
                s.used = true 
                if remake then 
                    s.value = self.fn_new()
                end
                return s
            end
        end
        if not found then 
            local new_uuid = uuid()
            local new_stack_obj = {
                uuid=new_uuid,
                used=true,
                value=self.fn_new(obj),
                is_stack=true
            }
            table.insert(self.stack, new_stack_obj)
            return new_stack_obj
        end
    end,
    release = function(self, object)
        for _, s in ipairs(self.stack) do 
            if s.uuid == object.uuid then 
                s.used = false
                return 
            end
        end
    end
}

CanvasStack = Stack(function()
    local canv = Canvas()
    canv:remDrawable()
    return canv
end)

--TRACK
track = nil
changed = nil
do 
    local obj_track = {} -- { table_ref={ var=last_val } }
    local tracks_changed = {} -- { table_ref={ var=new_value } }
    
    -- call track(obj, 'myvar') after it's been set
    --@global
    track = function(obj, comp_name)
        assert(obj, "track(): Object is nil") 
        if not obj_track[obj] then obj_track[obj] = {} end 
        obj_track[obj][comp_name] = obj[comp_name]
        --i = i + 1
        --print(i)
    end
    
    -- changed(obj, 'myvar') will return true/false if myvar has changed since the last track()/changed()
    changed = function(obj, comp_name)
        local last_vars = obj_track[obj]
        if last_vars then 
            if last_vars[comp_name] ~= obj[comp_name] then 
                if not tracks_changed[obj] then 
                    table.insert(tracks_changed, obj)
                    tracks_changed[obj] = {}
                end 
                tracks_changed[obj][comp_name] = obj[comp_name]
                return true
            end
        end
        return false
    end
    
    reset_tracks = function()
        table.update(obj_track, tracks_changed)
        tracks_changed = {}
    end
end

--FS
FS = nil 
do
    local lfs = love.filesystem
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
            return lfs.getDirectoryItems(path)
        end,
        info = function (path)
            if Window.os == 'web' then 
                local info = {
                    type = 'other',
                    size = lfs.getSize(path),
                    modtime = lfs.getLastModified(path)
                }
                if lfs.isFile(path) then info.type = "file"  
                elseif lfs.isDirectory(path) then info.type = "directory" 
                elseif lfs.isSymlink(path) then info.type = "symlink" end
                return info
            else
                return lfs.getInfo(path)
            end
        end
    }
end

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

--GAME
Game = nil
do
    local skip_tf = false
    local objects = {}

    local draw = function(props, lobj, is_fn)
        local parent = props.parent or props

        last_blend = nil
        if props.blendmode then
            last_blend = Draw.getBlendMode()
            Draw.setBlendMode(unpack(props.blendmode))
        end
        
        Game.checkAlign(props)
        local scalex, scaley = props.scalex * props.scale, props.scaley * props.scale
        local ax, ay = (props.alignx + props.offx) * scalex, (props.aligny + props.offy) * scaley
        local x = floor(props.x)
        local y = floor(props.y)

        local tform = props._draw_transform
        if not tform then 
            props._draw_transform = Draw.newTransform()
            tform = props._draw_transform
        end

        tform:reset()
        tform:translate(x,y)
        -- tform:translate(-ax / scalex, -ay / scaley) 
        if is_fn then 
            tform:scale(scalex, scaley)
            tform:rotate(math.rad(props.angle))
            tform:shear(props.shearx, props.sheary)
        end 


        local draw_obj = function()
            if not skip_tf then 
                Draw.applyTransform(props._draw_transform)
            end
            if is_fn then 
                lobj(props)
            else
                if props.quad then
                    love.graphics.draw(lobj, props.quad, 0,0,0, scalex, scaley, ax, ay, props.shearx, props.sheary)
                else
                    love.graphics.draw(lobj, 0,0,0, scalex, scaley, ax, ay, props.shearx, props.sheary)
                end
            end
        end

        Draw.push()
        if props.mesh and props.mesh.vertices then
            local mesh_canvas = CanvasStack:new()
            local mesh_str = (props.mesh.mode or 'fan')..'.'..(props.mesh.usage or 'dynamic')
            local mesh = Cache.get('mesh', mesh_str, function(key)
                return love.graphics.newMesh(props.mesh.vertices, props.mesh.mode or 'fan', props.mesh.usage or 'dynamic')
            end)
            skip_tf = true
            mesh_canvas.value:drawTo(function() draw_obj:draw() end)
            mesh:setTexture(mesh_canvas.value) -- yes twice (since it's a canvasstack)
            love.graphics.draw(mesh)
            CanvasStack:release(mesh_canvas)
            skip_tf = false
        else
            draw_obj()
        end

        if props.debug then
            local lax, lay = 0,0
            local rax, ray = Math.abs(ax), Math.abs(ay)
            
            local r = 5
            Draw.push()
            Draw.color('purple',0.75)
            Draw.rect('line',-rax,-ray,props.width or 0,props.height or 0)
            Draw{
                {'line',lax-r,lay-r,lax+r,lay+r},
                {'line',lax-r,lay+r,lax+r,lay-r},
            }
            Draw.pop()
        end
        Draw.applyTransform(props._draw_transform:inverse())
        Draw.pop()
        
        if last_blend then
            Draw.setBlendMode(last_blend)
        end
    end

    Game = class {
        options = {
            res =           'assets',
            scripts =       {},
            filter =        'linear',
            vsync =         1,
            auto_require =  true,
            background_color = 'black',
            window_flags = {},
            fps =           60,

            auto_draw =     true,
            scale =         true,
            effect =        nil,

            load =          function() end,
            draw =          function(d) d() end,
            postdraw =      nil,
            update =        function(dt) end,            
        };
        config = {};
        updatables = {};
        drawables = {};
        width = 0;
        height = 0;
        time = 0;
        love_version = {0,0,0};
        loaded = false;

        init = function(self,args)
            if not Game.loaded then
                Game.loaded = true
                table.update(Game.options, args)
                Game.load()
                if Game.options.initial_state then 
                    State.start(Game.options.initial_state)
                end
            end
            return nil
        end;

        updateWinSize = function(w,h)
            Window.width, Window.height, flags = love.window.getMode()
            if w and h then Window.width, Window.height = w, h end
            if Window.os == 'web' then
                Game.width, Game.height = Window.width, Window.height
            end
            if not Game.options.scale then
                Game.width, Game.height = Window.width, Window.height
                if Blanke.game_canvas then Blanke.game_canvas:resize(Game.width, Game.height) end
            end
        end;
        
        load = function()
            Game.time = 0
            Game.love_version = {love.getVersion()}
            -- load config.json
            config_data = love.filesystem.read('config.json')
            if config_data then Game.config = json.decode(config_data) end
            table.update(Game.options, Game.config.export)
            -- get current os
            if not Window.os then
                Window.os = ({ ["OS X"]="mac", ["Windows"]="win", ["Linux"]="linux", ["Android"]="android", ["iOS"]="ios" })[love.system.getOS()]-- Game.options.os or 'ide'
                Window.full_os = love.system.getOS()
            end
            -- load settings
            if Window.os ~= 'web' then
                Game.width, Game.height = Window.calculateSize(Game.config.game_size) -- game size
            end
            -- disable effects for web (SharedArrayBuffer or whatever)
            if Window.os == 'web' then
                Feature.disable('effect')
            end            
            -- window size and flags
            Game.options.window_flags = table.update({
                borderless = Game.options.frameless,
                resizable = Game.options.resizable,
            }, Game.options.window_flags or {})

            if Window.os ~= 'web' then
                Window.setSize(Game.config.window_size)
            end
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
                local load_folder
                load_folder = function(path)
                    files = FS.ls(path)
                    for _,f in ipairs(files) do
                        local file_path = path..'/'..f
                        if FS.extname(f) == 'lua' and not table.hasValue(scripts, file_path) then
                            new_f = 
                            table.insert(scripts, table.join(string.split(FS.removeExt(file_path), '/'),'.'))
                        end
                        local info = FS.info(file_path)
                        if info.type == 'directory' and file_path ~= '/dist' and file_path ~= '/lua' then 
                            load_folder(file_path)
                        end
                    end
                end
                load_folder('')
            end
            
            for _,script in ipairs(scripts) do
                if script ~= 'main' then 
                    require(script)
                end
            end
            -- fullscreen toggle
            Input.set({ _fs_toggle = { 'alt', 'enter' } }, { 
                combo = { '_fs_toggle' },
                no_repeat = { '_fs_toggle' },
            })
            -- effect
            if Game.options.effect then
                Game.setEffect(unpack(Game.options.effect))
            end
            if Game.options.load then
                Game.options.load()
            end
            
            love.graphics.setBackgroundColor(1,1,1,0)

            Blanke.game_canvas = Canvas()
            Blanke.game_canvas.__ide_obj = true
            
            Blanke.game_canvas:remDrawable()
        end;

        setEffect = function(...)
            Game.effect = Effect({...})
        end,

        addObject = function(name, _type, args, spawn_class)
            -- store in object 'library' and update initial props
            if objects[name] == nil then 
                objects[name] = {
                    type = _type,
                    args = args,
                    spawn_class = spawn_class
                }
            end
        end;

        checkAlign = function(obj)
            local align = obj.align 
            if obj.parent then align = obj.parent.align end
            local ax, ay = 0, 0
            if align then
                if string.contains(align, 'center') then
                    ax = obj.width/2 
                    ay = obj.height/2
                end
                if string.contains(align,'left') then
                    ax = 0
                end
                if string.contains(align, 'right') then
                    ax = obj.width
                end
                if string.contains(align, 'top') then
                    ay = 0
                end
                if string.contains(align, 'bottom') then
                    ay = obj.height
                end
            end
            obj.alignx, obj.aligny = floor(ax), floor(ay)
        end;

        sortDrawables = function()
            sort(Game.drawables, 'z', 0)
        end;
        
        updateObject = function(dt, obj)
            obj:_update(dt)
        end;

        drawObject = function(obj, lobj, is_fn)
            if obj.visible == false then return end
            if obj.effect then 
                obj.effect:draw(function()
                    draw(obj, lobj, is_fn)
                end)
            else 
                draw(obj, lobj, is_fn)
            end
        end;

        isSpawnable = function(name)
            return objects[name] ~= nil
        end;

        spawn = function(name, args)
            local obj_info = objects[name]
            if obj_info ~= nil and obj_info.spawn_class then
                args = args or {}
                args.is_entity = true
                args.classname = name
                local instance = obj_info.spawn_class(obj_info.args, args or {})
                return instance
            end
        end;

        count = function(classname)
            return gobject_count[classname] or 0
        end;

        res = function(_type, file)
            return Game.options.res.."/".._type.."/"..file
        end;

        setBackgroundColor = function(...)
            --love.graphics.setBackgroundColor(Draw.parseColor(...))
            Game.options.background_color = {Draw.parseColor(...)}
        end;

        update = function(dt)
            mouse_x, mouse_y = love.mouse.getPosition()
            if Game.options.scale == true then
                local scalex, scaley = Window.width / Game.width, Window.height / Game.height
                Blanke.scale = math.min(scalex, scaley)
                Blanke.padx, Blanke.pady = 0, 0
                if scalex > scaley then
                    Blanke.padx = floor((Window.width - (Game.width * Blanke.scale)) / 2)
                else 
                    Blanke.pady = floor((Window.height - (Game.height * Blanke.scale)) / 2)
                end
                -- offset mouse coordinates
                mouse_x = floor((mouse_x - Blanke.padx) / Blanke.scale)
                mouse_y = floor((mouse_y - Blanke.pady) / Blanke.scale)
            end

            Game.time = Game.time + dt
            if Game.options.update(dt) == true then return end
            Physics.update(dt)
            Timer.update(dt)
            Blanke.iterUpdate(Game.updatables, dt)
            State.update(dt)
            State._check()
            Signal.emit('update',dt)
            local key = Input.pressed('_fs_toggle') 
            if key and key.count == 1 then
                Window.toggleFullscreen()
            end            
            Input.keyCheck()
            Audio.update(dt)
        end
    }
end

--GAMEOBJECT
GameObject = nil 
do 
    GameObject = class {
        init = function(self, args, spawn_args)
            args = args or {}
            spawn_args = spawn_args or {}
            self.uuid = uuid()
            self.x, self.y, self.z, self.angle, self.scalex, self.scaley, self.scale = 0, 0, 0, 0, 1, 1, 1
            self.width, self.height, self.offx, self.offy, self.shearx, self.sheary = spawn_args.width or args.width or 1, spawn_args.height or args.height or 1, 0, 0, 0, 0
            self.align = nil
            self.blendmode = {'alpha'}
            self.visible = true
            self.child_keys = {}
            self.parent = nil

            self.net_vars = {'x','y','z','angle','scalex','scaley','scale','offx','offy','shearx','sheary','align','animation'}
            self.net_spawn_vars = copy(self.net_vars)

            -- custom properties were provided
            -- so far only allowed from Entity
            self.classname = spawn_args.classname or args.classname or 'GameObject'
            spawn_args.classname = nil; args.classname = nil

            if not gobject_count[self.classname] then gobject_count[self.classname] = 0 end 
            gobject_count[self.classname] = gobject_count[self.classname] + 1

            if args then
                args = copy(args)
                if args.net_vars then self.net_vars = args.net_vars end
                -- camera
                if args.camera and not spawn_args.net_obj then
                    local cam_type = type(args.camera)
                    if cam_type == 'table' then
                        for _,name in ipairs(args.camera) do
                            Camera.get(name).follow = self
                        end
                    else
                        Camera.get(args.camera).follow = self
                    end
                    args.camera = nil
                end
                -- effect
                if args.effect then 
                    self:setEffect(args.effect)
                    args.effect = nil
                end
                -- child entity
                for k, v in pairs(args) do
                    local arg_type = type(v)
                    local new_obj = nil
                    -- instantiation w/o args
                    if arg_type == "string" and Game.isSpawnable(v) then
                        new_obj = Game.spawn(v)
                    elseif is_object(v) then
                        table.insert(self.child_keys, k)
                        new_obj = v()
                    elseif arg_type == "table" then
                        -- instantiation with args
                        if type(v[1]) == "string" then
                            new_obj = Game.spawn(v[1], table.slice(v, 2))
                        elseif is_object(v[1]) then
                            table.insert(self.child_keys, k)
                            new_obj = v[1](unpack(table.slice(v, 2)))
                        end
                    end
                    if new_obj then
                        self[k] = new_obj
                        args[k] = nil
                    end
                end
                table.update(self, args)
            end
            if spawn_args then table.update(self,spawn_args) end
                        
            State.addObject(self)
            if not self.is_entity and self.spawn then self:spawn(unpack(spawn_args or {})) end
        end;
        addUpdatable = function(self)
            Blanke.addUpdatable(self)
        end;
        addDrawable = function(self)
            if self.__ide_obj or Game.options.auto_draw then 
                Blanke.addDrawable(self)
            end
        end;
        remUpdatable = function(self)
            self.updatable = false
        end;
        remDrawable = function(self)
            self.drawable = false
        end;
        setEffect = function(self, ...)
            self.effect = Effect(...)
        end;
        setMesh = function(self, verts)
            self.mesh = love.graphics.newMesh(verts,'fan')
        end;
        destroy = function(self)
            if not self.destroyed then
                Hitbox.remove(self)
                if self.ondestroy then self:ondestroy() end
                if self._destroy then self:_destroy() end
                if self.child_keys then
                    for _,k in ipairs(self.child_keys) do
                        self[k]:destroy() 
                    end
                end
                Net.destroy(self)
                self.destroyed = true
            
                if gobject_count[self.classname] then 
                    gobject_count[self.classname] = gobject_count[self.classname] - 1
                end 
            end
        end;
        __ = {
            tostring = function(self) return self.classname..'-'..self.uuid end
        }
    }
end

--CANVAS
local canv_len = 0 -- just a debug thing to see how many canvases exist
Canvas = GameObject:extend {
    init = function(self, w, h, settings)
        GameObject.init(self, {classname="Canvas"})
        w, h, settings = w or Game.width, h or Game.height, settings or {}
        self.auto_clear = true
        self.width = w
        self.height = h
        self.canvas = love.graphics.newCanvas(self.width, self.height, settings)
        self.quad = love.graphics.newQuad(0,0,Game.width,Game.height,Game.width,Game.height)
      
        canv_len = canv_len + 1
        self.blendmode = {"alpha"}
        self:addDrawable()
    end;
    reset = function(self)
        self.blendmode = {"alpha"}
        self.auto_clear = true
    end;
    _draw = function(self)  
        if not self.__ide_obj then
            Draw.push()
            love.graphics.origin()
        end
        Game.drawObject(self, self.canvas)
        if not self.__ide_obj then
            Draw.pop()
        end
    end;
    draw = function(self) self:_draw() end,
    resize = function(self,w,h) 
        self.width = w
        self.height = h
        self.canvas = love.graphics.newCanvas(w,h)
    end;
    prepare = function(self)
        if self.auto_clear then Draw.clear(self.auto_clear) end
        Draw.setBlendMode(unpack(self.blendmode))
        -- camera transform
        --love.graphics.origin()
        if Camera.transform and not self.__ide_obj then
            love.graphics.replaceTransform(Camera.transform)
        end
    end;
    drawTo = function(self,obj)
        Draw.stack(function()
            -- camera transform
            self.active = true
            self.canvas:renderTo(function()
                self:prepare()
                obj()
            end)
            self.active = false
        end)
    end;
}

--IMAGE
Image = nil
do 
    local animations = {}
    local info_cache = {}
    local getImage = function(name)
        local new_img = Cache.get('Image', Game.res('image',name), function(key)
            return love.graphics.newImage(key)
        end)
        assert(new_img, "Image not found:\'"..name.."\'")
        return new_img
    end
    
    ImageBatch = GameObject:extend {
        init = function(self, file)
            GameObject.init(self, {classname="ImageBatch"})
            
        end
    }

    Image = GameObject:extend {
        info = function(name)
            if animations[name] then return animations[name]
            else
                return Cache.get('Image.info', Game.res('image',name), function(key)
                    return {
                        img = love.graphics.newImage(key),
                        width = info.img:getWidth(),
                        height = info.img:getHeight()
                    }
                end)
            end
        end;
        -- options: cols, rows, offx, offy, frames ('1-3',4,5), duration, durations
        animation = function(file, anims, all_opt)
            all_opt = all_opt or {}
            local img = getImage(file)
            if not anims then 
                anims = {
                    { name=FS.removeExt(FS.basename(file)), cols=1, rows=1, frames={1} }
                }
            end
            if #anims == 0 then anims = {{}} end
            for _,anim in ipairs(anims) do
                local o = function(k) return anim[k] or all_opt[k] end
                local quads, durations = {}, {}
                local fw, fh = img:getWidth() / o('cols'), img:getHeight() / o('rows')
                local offx, offy = o('offx') or 0, o('offy') or 0
                -- calculate frame list
                local frame_list = {}
                local in_frames = o('frames') or {'1-'..(o('cols')*o('rows'))}
                
                assert(not in_frames or type(in_frames) == "table", "Image.animation frames must be in array")
                for _,f in ipairs(in_frames) do
                    local f_type = type(f)
                    if f_type == 'number' then
                        table.insert(frame_list, f)
                    elseif f_type == 'string' then
                        local a,b = string.match(f,'%s*(%d+)%s*-%s*(%d+)%s*')
                        for i = a,b do
                            table.insert(frame_list, i)
                        end
                    end
                end
                
                -- make quads
                for _,f in ipairs(frame_list) do
                    local x,y = Math.indexTo2d(f, o('cols'))
                    table.insert(quads, love.graphics.newQuad((x-1)*fw,(y-1)*fh,fw,fh,img:getWidth(),img:getHeight()))
                end
                animations[anim.name or FS.removeExt(FS.basename(file))] = {
                    file=file, 
                    duration=o('duration') or 1, 
                    durations=o('durations') or {}, 
                    quads=quads, 
                    w=fw, h=fh, frame_size={fw,fh}, 
                    speed=o('speed') or 1
                }
            end
        end;
        init = function(self,args)
            GameObject.init(self, {classname="Image"})
            -- animation?
            local anim_info = nil
            if type(args) == 'string' then
                anim_info = animations[args]
            elseif args.animation then
                anim_info = animations[args.animation]
            end
            if anim_info then 
                -- animation (speed, frame_index)
                args = {file=anim_info.file}
                self.animated = anim_info
                self.speed = anim_info.speed or 1
                self.t, self.frame_index, self.frame_len = 0, 1, anim_info.durations[1] or anim_info.duration
                self.quads = anim_info.quads
                self.frame_count = #self.quads
            elseif type(args) == 'string' then
                -- static image
                args = {file=args}
            end
            self.image = getImage(args.file)

            self:updateSize()
            if self._spawn then self:_spawn() end
            if self.spawn then self:spawn() end
            if not args.skip_update then 
                self:addUpdatable()
            end
            if args.draw == true then
                self:addDrawable()
            end
        end;
        updateSize = function(self)
            if self.animated then 
                self.width, self.height = abs(self.animated.frame_size[1] * self.scalex * self.scale), abs(self.animated.frame_size[2] * self.scaley * self.scale)
            else
                self.width = abs(self.image:getWidth() * self.scalex * self.scale)
                self.height = abs(self.image:getHeight() * self.scaley * self.scale)
            end
        end;
        update = function(self,dt)
            -- update animation
            if self.animated then
                self.t = self.t + (dt * self.speed)
                if self.t > self.frame_len then
                    self.frame_index = self.frame_index + 1
                    if self.frame_index > self.frame_count then self.frame_index = 1 end
                    info = self.animated
                    self.frame_len = info.durations[tostring(self.frame_index)] or info.duration
                    self.t = 0
                end
            end
        end;
        _draw = function(self)
            if self.destroyed then return end
            self:updateSize()
            if self.animated then 
                self.quad = self.quads[self.frame_index] 
            end
            Game.drawObject(self, self.image)
        end;
        draw = function(self) self:_draw() end
    }
end

--ENTITY
Entity = nil
do
    local updateEntity = function(self, dt) 
        local last_x, last_y = self.x, self.y
        local diff_pos = (self.x ~= last_x or self.y ~= last_y)
        if self.destroyed then return end
        if self.gravity ~= 0 then
            local gravx, gravy = Math.getXY(self.gravity_direction, self.gravity)
            self.hspeed = self.hspeed + gravx
            self.vspeed = self.vspeed + gravy
        end
        -- moving x and y in separate steps solves 'sticking' issue (ty https://jonathanwhiting.com/tutorial/collision/)
        
        self.x = self.x + self.hspeed * dt
        --if self.x ~= last_x then 
            Hitbox.move(self)
        --end
        self.y = self.y + self.vspeed * dt
        --if self.y ~= last_y then
            Hitbox.move(self)
        --end
        if self.update then self:update(dt) end
        if self.body then
            local new_x, new_y = self.body:getPosition()
            if self.x == last_x then self.x = new_x end
            if self.y == last_y then self.y = new_y end
            if diff_pos then
                self.body:setPosition(self.x, self.y)
            end
        end
        -- image/animation update
        for name, img in pairs(self.imageList) do
            img:update(dt)
        end
        for name, anim in pairs(self.animList) do
            anim:update(dt)
        end
        Net.sync(self)
    end
    -- (getMetaMethod)
    local getMM = function(self, name, ...)
        if self.__fn and self.__fn[name] then return self.__fn[name](self, ...) end
        return nil
    end
    local _Entity = GameObject:extend {
        __ = {
            tostring = function(self) return getMM(self, 'tostring') or self.classname..'-'..self.uuid end,
            unm = function(self,...) return getMM(self, 'unm', ...) or nil end,
            add = function(self,...) return getMM(self, 'add', ...) or nil end,
            sub = function(self,...) return getMM(self, 'sub', ...) or nil end,
            mul = function(self,...) return getMM(self, 'mul', ...) or nil end,
            div = function(self,...) return getMM(self, 'div', ...) or nil end,
            mod = function(self,...) return getMM(self, 'mod', ...) or nil end,
            pow = function(self,...) return getMM(self, 'pow', ...) or nil end,
            concat = function(self,...) return getMM(self, 'concat', ...) or nil end,
            eq = function(self,other) return getMM(self, 'eq', other) or self.uuid == other.uuid end,
            lt = function(self,...) return getMM(self, 'lt', ...) or nil end,
            le = function(self,...) return getMM(self, 'le', ...) or nil end,
        },
        init = function(self, args, spawn_args)
            self.hspeed = 0
            self.vspeed = 0
            self.gravity = 0
            self.gravity_direction = 90

            GameObject.init(self, args, spawn_args)

            self.imageList = {}
            self.animList = {}
            -- width/height already set?
            if self.width ~= 0 or self.height ~= 0 then 
                self._preset_size = true
            end
            -- image
            if args.images then
                if type(args.images) == 'table' then
                    for _,img in ipairs(args.images) do
                        self.imageList[img] = Image{file=img, skip_update=true}
                    end
                    self:_updateSize(self.imageList[args.images[1]], true)
                else 
                    self.imageList[args.images] = Image{file=args.images, skip_update=true}
                    self:_updateSize(self.imageList[args.images], true)
                end
                self.images = args.images
            end
            -- animation
            if args.animations then
                if type(args.animations) == 'table' then
                    for _, anim_name in ipairs(args.animations) do 
                        if not args.animation then 
                            args.animation = anim_name 
                        end
                        self.animList[anim_name] = Image{file=args, animation=anim_name, skip_update=true}
                    end
                else  
                    if not args.animation then 
                        args.animation = args.animations 
                    end
                    self.animList[args.animations] = Image{file=args, animation=args.animations, skip_update=true}
                end    
                self.anim_speed = args.anim_speed or spawn_args.anim_speed or self.anim_speed
                self.anim_frame = args.anim_frame or spawn_args.anim_frame or self.anim_frame
                self.animation = args.animation or spawn_args.animation 
                self:_updateSize(self.animList[self.animation], true)
            end

            if not self.reaction then
                self.reaction = 'cross'
                if args.animations or args.images then 
                    self.reaction = 'slide'
                end
            end

            for _,img in pairs(self.imageList) do img.parent = self end
            for _,anim in pairs(self.animList) do anim.parent = self end
            Game.checkAlign(self)
            -- physics
            assert(not (args.body and args.fixture), "Entity can have body or fixture. Not both!")
            if args.body then
                Physics.body(self.classname, args.body)
                self.body = Physics.body(self.classname)
            end
            if args.joint then
                Physics.joint(self.classname, args.joint)
                self.joint = Physics.joint(self.classname)
            end
            -- hitbox
            if args.hitbox then
                self.hitbox = copy(args.hitbox)
                Hitbox.add(self)
            end
            -- net
            if args.net and not spawn_args.net_obj then
                spawn_args.anim_frame = args.anim_frame
                spawn_args.anim_speed = args.anim_speed
                spawn_args.x = spawn_args.x or self.x 
                spawn_args.y = spawn_args.y or self.y 
                Net.spawn(self, spawn_args)
            end
            -- metamethods
            if args.__ then 
                self.__fn = args.__
                args.__ = nil
            end
            self.net_obj = spawn_args.net_obj
            -- other props
            for _, fn in ipairs(Entity.init_props) do
                fn(self, args, spawn_args)
            end
            self:addUpdatable()
            self:addDrawable()
            table.update(self, spawn_args or {})
            if self.spawn then 
                if spawn_args then self:spawn(unpack(spawn_args))
                else self:spawn() end 
            end
            if self.hasHitbox then
                Hitbox.teleport(self)
            end
            if self.body then self.body:setPosition(self.x, self.y) end
        end;
        _updateSize = function(self,obj,skip_anim_check)
            if self.animation then
                local anim = self.animList[self.animation]
                assert(skip_anim_check or anim, self.classname.." missing animation '"..self.animation.."'")
                -- change animation values from here?
                if self.anim_speed then 
                    anim.speed = self.anim_speed
                    Net.sync(self, {'anim_speed'})
                end
                if self.anim_frame then 
                    anim.frame_index = self.anim_frame
                    Net.sync(self, {'anim_frame'})
                end
            end 
            if not self._preset_size then
                self.width, self.height = abs(obj.width * self.scalex*self.scale), abs(obj.height * self.scaley*self.scale)
            end
        end;
        _checkForAnimHitbox = function(self)
            if self.hitbox == true then self.hitbox = self.image or self.animation end
            if self.animList[self.hitbox] or self.imageList[self.hitbox] then
                local other_obj = self.animList[self.hitbox] or self.imageList[self.hitbox]
                self.width, self.height = abs(other_obj.width * self.scalex*self.scale), abs(other_obj.height * self.scaley*self.scale)
                Game.checkAlign(self)
                return true
            end
        end,
        _update = function(self,dt)
            updateEntity(self, dt)
        end;
        netSync = function(self, props, spawning) 
            if self.animation and (spawning or self.anim_speed ~= nil) then
                props.anim_frame = self.anim_frame
                props.anim_speed = self.animList[self.animation].speed
                return 2
            end
        end,
        _draw = function(self)       
            Game.drawObject(self, function()
                -- predraw
                if self.predraw then
                    self:predraw()
                end
                -- draw
                local draw_fn = function()
                    if self.imageList then
                        for name, img in pairs(self.imageList) do
                            img:draw()
                        end
                    end
                    if self.animation and self.animList[self.animation] then
                        local anim = self.animList[self.animation]
                        self:_updateSize(anim)
                        anim:draw()
                        if not self._preset_size then
                            self.width, self.height = anim.width, anim.height
                        end
                    end
                end
                if self._custom_draw then
                    self:_custom_draw(draw_fn)
                else
                    draw_fn()
                end
                -- postdraw 
                if self.postdraw then 
                    self:postdraw()
                end
            end, 'function')
        end;
        draw = function(self) self:_draw() end;
        _destroy = function(self)
            if self.destroyed then return end
            for name, img in pairs(self.imageList) do
                img:destroy()
            end
            for name, anim in pairs(self.animList) do
                anim:destroy()
            end
        end
    }
    
    Entity = callable {
        init_props = {};
        __call = function(self, name, args)
            if args.draw then
                args._custom_draw = args.draw
                args.draw = nil
            end
            Game.addObject(name, "Entity", args, _Entity)
            return callable{
                __call = function(self, args)
                    return Game.spawn(name, args)
                end,
                count = function()
                    return Game.count(name)
                end
            }
        end;
        addInitFn = function(fn)
            table.insert(Entity.init_props, fn)
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
    local store = {}
    local key_assoc = {
        lalt='alt', ralt='alt',
        ['return']='enter', kpenter='enter',
        lgui='gui', rgui='gui'
    }

    local joycheck = function(info)
        if not info or not info.joystick then return info end 
        if Joystick.using == 0 then return info end 
        if Joystick.get(Joystick.using):getID() == info.joystick:getID() then return info end
    end

    Input = callable {
        __call = function(self, name)
            return store[name] or pressed[name] or released[name]
        end;

        store = function(name, value)
            store[name] = value
        end;

        set = function(inputs, _options)
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

        pressed = function(name) 
            if not (table.hasValue(options.no_repeat, name) and pressed[name] and pressed[name].count > 1) and joycheck(pressed[name]) then 
                return pressed[name] 
            end 
        end;

        released = function(name)
            if joycheck(released[name]) then
                return released[name] 
            end
        end;

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

--JOYSTICK
Joystick = nil
local refreshJoystickList
do 
    local joysticks = {}
    refreshJoystickList = function()
        joysticks = love.joystick.getJoysticks()
    end

    Joystick = {
        using = 0,
        get = function(i)
            if i > 0 and i < #joysticks then 
                return joysticks[i]
            end
        end,
        -- affects all future Input() gamepad checks
        use = function(i)
            Joystick.using = i or 0
        end
    }
end

--DRAW
Draw = nil 
do
    local clamp = Math.clamp
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
        local font = love.graphics.newFont(Game.res('font',path), size)
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
            x = x or 0
            y = y or 0
            if not char_limit then 
                char_limit = Draw.getFont():getWidth(txt)
            end
            love.graphics.printf(txt,x,y,char_limit,align,...)
        end;
        parseColor = function(...)
            args = {...}
            if #args == 0 then return 1, 1, 1, 1 end
            local c = Color[args[1]]
            if c then 
                args = {c[1],c[2],c[3], args[2] or 1}
                for a,arg in ipairs(args) do 
                    if arg > 1 then args[a] = arg / 255 end
                end
            end
            if #args == 0 then args = {1,1,1,1} end
            if not args[4] then args[4] = 1 end
            return args[1], args[2], args[3], clamp(args[4], 0, 1)
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

--AUDIO
Audio = nil
do
    local default_opt = {
        type = 'static'
    }
    local defaults = {}
    local sources = {}
    local new_sources = {}
    local play_queue = {}
    local first_update = true

    local opt = function(name, overrides)
        if not defaults[name] then Audio(name, {}) end
        return defaults[name]
    end
    Audio = class {
        init = function(self, file, ...)
            option_list = {...}
            for _,options in ipairs(option_list) do
                store_name = options.name or file
                options.file = file
                if not defaults[store_name] then defaults[store_name] = {} end
                new_tbl = copy(default_opt)
                table.update(new_tbl, options)
                table.update(defaults[store_name], new_tbl)
            end
        end;

        update = function(dt)
            if #play_queue > 0 then 
                for _, src in ipairs(play_queue) do 
                    love.audio.play(src)
                end
                play_queue = {}
            end
        end;
        
        source = function(name, options)
            local o = opt(name)
            if options then o = table.update(o, options) end

            if Window.os == 'web' then o.type = 'static' end

            local src = Cache.get('Audio.source',name,function(key)
                return love.audio.newSource(Game.res('audio',o.file), o.type)
            end)
            
            if not sources[name] then
                sources[name] = love.audio.newSource(Game.res('audio',o.file), o.type)
            end
            if not new_sources[name] then new_sources[name] = {} end

            if o then
                table.insert(new_sources[name], src)
                local props = {'looping','volume','airAbsorption','pitch','relative','rolloff'}
                local t_props = {'position','attenuationDistances','cone','direction','velocity','filter','effect','volumeLimits'}
                for _,n in ipairs(props) do
                    if o[n] then 
                        src['set'..n:capitalize()](src,o[n]) 
                    end
                end
                for _,n in ipairs(t_props) do
                    if o[n] then src['set'..n:capitalize()](src,unpack(o[n])) end
                end
            end
            return src
        end;
        play = function(...)
            local src_list = {}
            for _,name in ipairs({...}) do 
                table.insert(src_list, Audio.source(name)) 
                -- adds to play_queue so audio doesn't play in Game.load (before the game actually starts)
                table.insert(play_queue, Audio.source(name))
            end
            if #src_list == 1 then return src_list[1] 
            else return src_list end
        end;
        stop = function(...) 
            names = {...}
            if #names == 0 then love.audio.stop() 
            else
                for _,n in ipairs(names) do
                    if new_sources[n] then 
                        for _,src in ipairs(new_sources[n]) do love.audio.stop(src) end 
                    end
                end
            end
        end;
        isPlaying = function(name)
            if new_sources[name] then 
                local t = {}
                for _,src in ipairs(new_sources[name]) do 
                    if src:isPlaying() then return true end
                end
            end
            return false
        end;
    }

    local audio_fns = {'volume','velocity','position','orientation','effect','dopp'}
    for _, fn in ipairs(audio_fns) do 
        local fn_capital = fn:capitalize()
        Audio[fn] = function(...)
            local args = {...}
            if #args > 0 then love.audio['set'..fn_capital](...)
            else return love.audio['get'..fn_capital]() end
        end
    end
end

--EFFECT
Effect = nil
do
    local love_replacements = {
        float = "number",
        int = "number",
        sampler2D = "Image",
        uniform = "extern",
        texture2D = "Texel",
        gl_FragColor = "pixel",
        gl_FragCoord = "screen_coords"
    }          
    local helper_fns = [[
/* From glfx.js : https://github.com/evanw/glfx.js */
float random(vec2 scale, vec2 pixelcoord, float seed) {
    /* use the fragment position for a different seed per-pixel */
    return fract(sin(dot(pixelcoord + seed, scale)) * 43758.5453 + seed);
}
float mod(float a, float b) { return - (a / b) * b; }
float getX(float amt) { return amt / love_ScreenSize.x; }
float getY(float amt) { return amt / love_ScreenSize.y; }
float lerp(float a, float b, float t) { return a * (1.0 - t) + b * t; }
]]
    local library = {}
    local shaders = {} -- { 'eff1+eff2' = { shader: Love2dShader } }

    local tryEffect = function(name)
        assert(library[name], "Effect :'"..name.."' not found")
    end

    local _generateShader, generateShader

    generateShader = function(names, override)
        if type(names) ~= 'table' then
            names = {names}
        end
        local ret_shaders = {}
        for _, name in ipairs(names) do 
            ret_shaders[name] = _generateShader(name, override)
        end
        return ret_shaders
    end

    local shader_obj = {} -- { name : LoveShader }
    _generateShader = function(name, override)
        tryEffect(name)
        local info = library[name]
        local shader = shader_obj[name] or love.graphics.newShader(info.code)
        if override then 
            shader = love.graphics.newShader(info.code)
        end
        shader_obj[name] = shader

        return {
            vars = copy(info.opt.vars),
            unused_vars = copy(info.opt.unused_vars),
            shader = shader
        }
    end

    Effect = GameObject:extend {
        new = function(name, in_opt)
            local opt = { use_canvas=true, vars={}, unused_vars={}, integers={}, code=nil, effect='', vertex='' }
            table.update(opt, in_opt)
            
            -- mandatory vars
            if not opt.vars['tex_size'] then
                opt.vars['tex_size'] = {Game.width, Game.height}
            end
            if not opt.vars['time'] then
                opt.vars['time'] = 0
            end
            
            -- create var string
            var_str = ""
            for key, val in pairs(opt.vars) do
                -- unused vars?
                if not string.contains(opt.code or (opt.effect..' '..opt.vertex), key) then
                    opt.unused_vars[key] = true
                end
                -- get var type
                switch(type(val),{
                    table = function() 
                        var_str = var_str.."uniform vec"..tostring(#val).." "..key..";\n" 
                    end,
                    number = function()
                        if table.hasValue(opt.integers, key) then
                            var_str = var_str.."uniform int "..key..";\n"
                        else
                            var_str = var_str.."uniform float "..key..";\n"
                        end
                    end,
                    string = function()
                        if val == "Image" then
                            var_str = var_str.."uniform Image "..key..";\n"
                        end
                    end
                })
            end

            local code = var_str.."\n"..helper_fns.."\n"
            if opt.code then
                code = code .. opt.code
            else 
                code = code .. [[   

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position) {
    ]]..(opt.position or '')..[[
    return transform_projection * vertex_position;
}
#endif


#ifdef PIXEL
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = Texel(texture, texture_coords);
    ]]..(opt.effect or '')..[[
    return pixel * color;
}
#endif
                    ]]
            end

            for old, new in pairs(love_replacements) do
                code = code:replace(old, new, true)
            end

            library[name] = {
                opt = copy(opt),
                code = code
            }

        end;

        info = function(name) return library[name] end;
        
        init = function(self, ...)
            GameObject.init(self, {classname="Effect"})

            self.names = {...}
            if type(self.names[1]) == 'table' then
                self.names = self.names[1]
            end
            
            if Feature('effect') then
                self.used = true
                self.vars = {}
                self.disabled = {}
                self:updateShader(self.names)

                self:addUpdatable()
            end
        end;
        __ = {
            -- eq = function(self, other) return self.shader_info.name == other.shader_info.name end,
            -- tostring = function(self) return self.shader_info.code end
        };
        updateShader = function(self, names)
            if not Feature('effect') then return end
            self.shader_info = generateShader(names)
            for _, name in ipairs(names) do
                if not self.vars[name] then self.vars[name] = {} end 
                table.update(self.vars[name], self.shader_info[name].vars)
            end
        end;
        disable = function(self, ...)
            if not Feature('effect') then return end
            local disable_names = {...}
            for _,name in ipairs(disable_names) do self.disabled[name] = true end 
            local new_names = {}
            for _,name in ipairs(self.names) do 
                tryEffect(name)
                if not self.disabled[name] then 
                    table.insert(new_names, name)
                end
            end
            self:updateShader(new_names)
        end;
        enable = function(self, ...)
            if not Feature('effect') then return end
            local enable_names = {...}
            for _,name in ipairs(enable_names) do self.disabled[name] = false end 
            local new_names = {}
            for _,name in ipairs(self.names) do 
                tryEffect(name)
                if not self.disabled[name] then 
                    table.insert(new_names, name)
                end
            end
            self:updateShader(new_names)
        end;
        set = function(self,name,k,v)
            if not Feature('effect') then return end
            -- tryEffect(name)
            if not self.disabled[name] then
                if not self.vars[name] then 
                    self.vars[name] = {}
                end
                self.vars[name][k] = v
            end
        end;
        send = function(self,name,k,v)
            if not Feature('effect') then return end
            local info = self.shader_info[name]
            if not info.unused_vars[k] then
                tryEffect(name)
                if info.shader:hasUniform(k) then
                    info.shader:send(k,v)
                end
            end
        end;
        _update = function(self,dt)
            if not Feature('effect') then return end
            local vars
            local used = #self.names

            for _,name in ipairs(self.names) do
                vars = self.vars[name]
                if not self.disabled[name] then
                    vars.time = vars.time + dt
                    vars.tex_size = {Game.width,Game.height}
                    -- send all the vars
                    for k,v in pairs(vars) do
                        self:send(name, k, v)
                    end
                else
                    used = used - 1
                end
                if not self.disabled[name] and library[name] and library[name].opt.update then
                    library[name].opt.update(self.vars[name])
                end
            end

            self.used = (used >= 0)
        end;
        update = function(self,dt) 
            self:_update(dt) 
        end;
        active = 0;
        --@static
        isActive = function()
            return Effect.active > 0
        end;
        draw = function(self, fn)
            if not self.used or not Feature('effect') then
                fn()
                return
            end      

            Effect.active = Effect.active + 1

            local last_shader = love.graphics.getShader()
            local last_blend = love.graphics.getBlendMode()

            local canv_internal, canv_final = CanvasStack:new(), CanvasStack:new()
            
            canv_internal.value.auto_clear = {Draw.parseColor(Game.options.background_color, 0)}
            canv_final.value.auto_clear = {Draw.parseColor(Game.options.background_color, 0)}
            
            for i, name in ipairs(self.names) do 
                -- draw without shader first
                canv_internal.value:drawTo(function()
                    love.graphics.setShader()
                    if i == 1 then
                        -- draw unshaded stuff (first run)
                        fn()
                    else 
                        -- draw previous shader results
                        canv_final.value:draw()
                    end
                end)

                -- draw to final canvas with shader
                canv_final.value:drawTo(function()
                    love.graphics.setShader(self.shader_info[name].shader)
                    canv_internal.value:draw()
                end)
            end

            -- draw final resulting canvas
            canv_final.value:draw()
            
            love.graphics.setShader(last_shader)
            love.graphics.setBlendMode(last_blend)

            CanvasStack:release(canv_internal)
            CanvasStack:release(canv_final)

            Effect.active = Effect.active - 1
        end;
    }
end

--CAMERA
Camera = nil
do
    local default_opt = { x=0, y=0, dx=0, dy=0, angle=0, zoom=nil, scalex=1, scaley=nil, top=0, left=0, width=nil, height=nil, follow=nil, enabled=true }
    local attach_count = 0
    local options = {}

    Camera = class {
        transform = nil;
        init = function(self, name, opt)
            opt = opt or {}
            options[name] = copy(default_opt)
            options[name].transform = love.math.newTransform()
            table.update(options[name], opt)
            return options[name]
        end;
        get = function(name) return assert(options[name], "Camera :'"..name.."' not found") end;
        attach = function(name)
            o = Camera.get(name)
            Draw.push()
            if o.enabled == false then return end
            if o then
                local w, h = o.width or Game.width, o.height or Game.height
                if o.follow then
                    o.x = o.follow.x or o.x
                    o.y = o.follow.y or o.y
                end
                local half_w, half_h = w/2, h/2
                -- Draw.crop(o.x - o.left, o.y - o.top, w, h)
                o.transform:reset()
                o.transform:translate(floor(half_w), floor(half_h))
                o.transform:scale(o.zoom or o.scalex, o.zoom or o.scaley or o.scalex)
                o.transform:rotate(math.rad(o.angle))
                o.transform:translate(-floor(o.x - o.left + o.dx), -floor(o.y - o.top + o.dy))

                Camera.transform = o.transform
                love.graphics.replaceTransform(o.transform)
            end
        end;
        detach = function()
            Draw.pop()
        end;
        use = function(name, fn)
            Camera.attach(name)
            fn()
            Camera.detach()
        end;
        count = function() return table.len(options) end;
        useAll = function(fn)
            for name, opt in pairs(options) do
                Camera.use(name, fn)
            end
        end;
    }
end

--SPRITEBATCH
SpriteBatch = nil
do 
    local images = {} -- { name: Image }
    local quads = {} -- { hash: Quad }
    SpriteBatch = GameObject:extend {
        init = function(self)
            GameObject.init(self, {classname="Map"})
    
            self.batches = {} -- { 'file_name' = SpriteBatch }
            self:addDrawable()
        end;
        add = function(self, img_path, x, y, tx, ty, tw, th)
            -- get image
            local img = images[img_path]
            if not img then images[img_path] = love.graphics.newImage(img_path) end 
            img = images[img_path]
    
            -- get quad
            local quad_hash = tx..","..ty..","..tw..","..ty
            if not quads[quad_hash] then quads[quad_hash] = love.graphics.newQuad(tx,ty,tw,th,img:getWidth(),img:getHeight()) end
            local quad = quads[quad_hash]
    
            -- get spritebatch
            local sb = self.batches[img_path]
            if not sb then sb = love.graphics.newSpriteBatch(img) end 
            self.batches[img_path] = sb
    
            return sb:add(quad,floor(x),floor(y),0)
        end;
        remove = function(self, img_path, id)
            local sb = self.batches[img_path]
            if sb then 
                sb:set(id, 0, 0, 0, 0, 0) 
                return true 
            end
        end;
        _draw = function(self)
            for _, sb in pairs(self.batches) do 
                Game.drawObject(self, sb)
            end
        end;
        draw = function(self) self:_draw() end;
    }
end

--MAP
Map = nil
do
    local options = {}
    local getObjInfo = function(uuid, is_name)
        if Game.config.scene and Game.config.scene.objects then 
            if is_name then
                for uuid, info in pairs(Game.config.scene.objects) do
                    if info.name == uuid then
                        return info
                    end
                end
            else
                return Game.config.scene.objects[uuid]
            end
        end
    end
    Map = GameObject:extend {
        load = function(name)
            local data = love.filesystem.read(Game.res('map',name))
            assert(data,"Error loading map '"..name.."'")
            local new_map = Map()
            data = json.decode(data)
            new_map.data = data
            local layer_name = {}
            -- get layer names
            local store_layer_order = false
            if not options.layer_order then
                options.layer_order = {}
                store_layer_order = true
            end
            for i,info in ipairs(data.layers) do
                layer_name[info.uuid] = info.name
                if store_layer_order then
                    table.insert(options.layer_order, info.name)
                end
            end
            -- place tiles
            for _,img_info in ipairs(data.images) do
                for l_uuid, coord_list in pairs(img_info.coords) do
                    l_name = layer_name[l_uuid]
                    for _,c in ipairs(coord_list) do
                        new_map:addTile(img_info.path,c[1],c[2],c[3],c[4],c[5],c[6],l_name)
                    end
                end
            end
            -- spawn entities/hitboxes
            for obj_uuid, info in pairs(data.objects) do
                local obj_info = getObjInfo(obj_uuid)
                if obj_info then
                    for l_uuid, coord_list in pairs(info) do
                        for _,c in ipairs(coord_list) do
                            local hb_color = Draw.hexToRgb(obj_info.color)
                            hb_color[4] = 0.3
                            -- spawn entity
                            if Game.isSpawnable(obj_info.name) then
                                local obj = new_map:_spawnEntity(obj_info.name,{
                                    map_tag=c[1], x=c[2], y=c[3], z=new_map:getLayerZ(layer_name[l_uuid]), layer=layer_name[l_uuid], points=copy(c),
                                    width=obj_info.size[1], height=obj_info.size[2], hitboxColor=hb_color
                                })
                            -- spawn hitbox
                            else 
                                new_map:addHitbox(table.join({obj_info.name, c[1]},'.'), table.slice(c,2), hb_color)
                            end
                            -- add info to entity_info table
                            if not new_map.entity_info[obj_info.name] then new_map.entity_info[obj_info.name] = {} end 
                            table.insert(new_map.entity_info[obj_info.name], {
                                map_tag=c[1], x=c[2], y=c[3], z=new_map:getLayerZ(layer_name[l_uuid]), layer=layer_name[l_uuid], points=copy(c),
                                width=obj_info.size[1], height=obj_info.size[2], color=hb_color
                            })
                        end
                    end
                end
            end
            
            return new_map
        end;
        config = function(opt) options = opt end;
        init = function(self)
            GameObject.init(self, {classname="Map"})
            self.batches = {} -- { layer: SpriteBatch }
            self.hb_list = {}
            self.entity_info = {} -- { obj_name: { info_list... } }
            self.entities = {} -- { layer: { entities... } }
        end;
        addTile = function(self,file,x,y,tx,ty,tw,th,layer)
            layer = layer or '_'
    
            -- get spritebatch 
            local sb = self.batches[layer]
            if not sb then sb = SpriteBatch(file) end 
            self.batches[layer] = sb
            local id = sb:add(file, x, y, tx, ty, tw, th)
            sb.z = self:getLayerZ(layer)
            
            -- hitbox
            local hb_name = nil
            if options.tile_hitbox then hb_name = options.tile_hitbox[FS.removeExt(FS.basename(file))] end
            local body = nil
            local tile_info = { id=id, x=x, y=y, width=tw, height=th, tag=hb_name, alignx=tw/2, aligny=th/2 }
            if hb_name then
                tile_info.tag = hb_name
                if options.use_physics then
                    hb_key = hb_name..'.'..tw..'.'..th
                    if not Physics.getBodyConfig(hb_key) then
                        Physics.body(hb_key, {
                            shapes = {
                                {
                                    type = 'rect',
                                    width = tw,
                                    height = th,
                                    offx = tw/2,
                                    offy = th/2
                                }
                            }
                        })
                    end
                    local body = Physics.body(hb_key)
                    body:setPosition(x,y)
                    tile_info.body = body
                end
            end
            if not options.use_physics and tile_info.tag then
                Hitbox.add(tile_info)
                table.insert(self.hb_list, tile_info)
            end
        end;
        addHitbox = function(self,tag,dims,color) 
            local new_hb = {
                hitbox = dims,
                tag = tag,
                hitboxColor = color,
            }
            table.insert(self.hb_list, new_hb)
            Hitbox.add(new_hb)
        end,
        _spawnEntity = function(self, ent_name, opt)
            local obj = Game.spawn(ent_name, opt)
            if obj then
                opt.layer = opt.layer or "_"
                if not self.entities[opt.layer] then self.entities[opt.layer] = {} end
                table.insert(self.entities[opt.layer], obj)
                return obj
            end
        end;
        spawnEntity = function(self, ent_name, x, y, layer)
            layer = layer or "_"
            obj_info = getObjInfo(ent_name, true)
            if obj_info then
                obj_info.x = x
                obj_info.y = y
                obj_info.z = self:getLayerZ(layer)
                obj_info.layer = layer
                return self:_spawnEntity(ent_name, obj_info)
            end
        end;
        -- return { {x,y,z,layer(name),points,width,height,color} }
        getEntityInfo = function(self, name)
            return self.entity_info[name] or {}
        end;
        getEntities = function(self, name)
            return self.entities
        end;
        getLayerZ = function(self, l_name)
            for i, name in ipairs(options.layer_order) do
                if name == l_name then return i end
            end
            return 0
        end;
        _destroy = function(self) 
            -- destroy hitboxes
            for _,tile in ipairs(self.hb_list) do 
                Hitbox.remove(tile)
            end
            -- destroy entities
            for _,entities in pairs(self.entities) do
                for _,ent in ipairs(entities) do
                    ent:destroy()
                end
            end
            -- destroy spritebatches
            for _,batch in pairs(self.batches) do 
                batch:destroy()
            end
        end
    }
end

--PHYSICS
Physics = nil
do 
    local world_config = {}
    local body_config = {}
    local joint_config = {}
    local worlds = {}

    local setProps = function(obj, src, props)
        for _,p in ipairs(props) do 
            if src[p] ~= nil then obj['set'..string.capitalize(p)](obj,src[p]) end
        end
    end

    --PHYSICS.BODYHELPER
    local BodyHelper = class {
        init = function(self, body)
            self.body = body
            self.body:setUserData(helper)
            self.gravx, self.gravy = 0, 0
            self.grav_added = false
        end;
        update = function(self, dt)
            if self.grav_added then
                self.body:applyForce(self.gravx,self.gravy)
            end
        end;
        setGravity = function(self, angle, dist)
            if dist > 0 then
                self.gravx, self.gravy = Math.getXY(angle, dist)
                self.body:setGravityScale(0)
                if not self.grav_added then
                    table.insert(Physics.custom_grav_helpers, self)
                    self.grav_added = true
                end
            end
        end;
        setPosition = function(self, x, y)
            self.body:setPosition(x,y)
        end
    }
    
    Physics = class {
        custom_grav_helpers = {};
        debug = false;
        update = function(dt)
            for name, world in pairs(worlds) do
                local config = world_config[name]
                world:update(dt,8*config.step_rate,3*config.step_rate)
            end
            for _,helper in ipairs(Physics.custom_grav_helpers) do
                helper:update(dt)
            end
        end;
        getWorldConfig = function(name) return world_config[name] end;
        world = function(name, opt)
            if type(name) == 'table' then
                opt = name 
                name = '_default'
            end 
            name = name or '_default'
            if opt or not world_config[name] then
                world_config[name] = opt or {}
                table.defaults(world_config[name], {
                    gravity = 0,
                    gravity_direction = 90,
                    sleep = true,
                    step_rate = 1
                })
            end
            if not worlds[name] then
                worlds[name] = love.physics.newWorld()
            end
            local w = worlds[name]
            local c = world_config[name]
            -- set properties
            w:setGravity(Math.getXY(c.gravity_direction, c.gravity))
            w:setSleepingAllowed(c.sleep)
            return worlds[name]
        end;            
        getJointConfig = function(name) return joint_config[name] end;
        joint = function(name, opt) -- TODO: finish joints
            if not worlds['_default'] then Physics.world('_default', {}) end
            if opt then
                joint_config[name] = opt
            end
        end;
        getBodyConfig = function(name) return body_config[name] end;
        body = function(name, opt)
            if not worlds['_default'] then Physics.world('_default', {}) end
            if opt then
                body_config[name] = opt
                table.defaults(body_config[name], {
                    x = 0,
                    y = 0,
                    angularDamping = 0,
                    gravity = 0,
                    gravity_direction = 0,
                    type = 'static',
                    fixedRotation = false,
                    bullet = false,
                    inertia = 0,
                    linearDamping = 0,
                    shapes = {}
                })
                return
            end
            assert(body_config[name], "Physics config missing for '#{name}'")
            local c = body_config[name]
            if not c.world then c.world = '_default' end
            assert(worlds[c.world], "Physics world '#{c.world}' config missing (for body '#{name}')")
            -- create the body
            local body = love.physics.newBody(worlds[c.world], c.x, c.y, c.type)
            local helper = BodyHelper(body)
            -- set props
            setProps(body, c, {'angularDamping','fixedRotation','bullet','inertia','linearDamping','mass'})
            helper:setGravity(c.gravity, c.gravity_direction)
            local shapes = {}
            for _,s in ipairs(c.shapes) do
                local shape = nil
                table.defaults(s, {
                    density = 0
                })
                switch(s.type,{
                    rect = function()
                        table.defaults(s, {
                            width = 1,
                            height = 1,
                            offx = 0,
                            offy = 0,
                            angle = 0
                        })
                        shape = love.physics.newRectangleShape(c.x+s.offx,c.y+s.offy,s.width,s.height,s.angle)
                    end,
                    circle = function()
                        table.defaults(s, {
                            offx = 0,
                            offy = 0,
                            radius = 1
                        })
                        shape = love.physics.newCircleShape(c.x+s.offx,c.y+s.offy,s.radius)
                    end,
                    polygon = function()
                        table.defaults(s, {
                            points = {}
                        })
                        assert(#s.points >= 6, "Physics polygon must have 3 or more vertices (for body '"..name.."')")
                        shape = love.physics.newPolygonShape(s.points)
                    end,
                    chain = function()
                        table.defaults(s, {
                            loop = false,
                            points = {}
                        })
                        assert(#s.points >= 4, "Physics polygon must have 2 or more vertices (for body '"..name.."')")
                        shape = love.physics.newChainShape(s.loop, s.points)
                    end,
                    edge = function()
                        table.defaults(s, {
                            points = {}
                        })
                        assert(#s.points >= 4, "Physics polygon must have 2 or more vertices (for body '"..name.."')")
                        shape = love.physics.newEdgeShape(unpack(s.points))
                    end
                })
                if shape then 
                    fix = love.physics.newFixture(body,shape,s.density)
                    setProps(fix, s, {'friction','restitution','sensor','groupIndex'})
                    table.insert(shapes, shape)
                end
            end
            return body, shapes
        end;
        setGravity = function(body, angle, dist)
            local helper = body:getUserData()
            helper:setGravity(angle, dist)
        end;
        draw = function(body, _type)
            for _, fixture in pairs(body:getFixtures()) do
                shape = fixture:getShape()
                if shape:typeOf("CircleShape") then
                    local x, y = body:getWorldPoints(shape:getPoint())
                    Draw.circle(_type or 'fill', floor(x), floor(y), shape:getRadius())
                elseif shape:typeOf("PolygonShape") then
                    local points = {body:getWorldPoints(shape:getPoints())}
                    for i,p in ipairs(points) do points[i] = floor(p) end
                    Draw.poly(_type or 'fill', points)
                else 
                    local points = {body:getWorldPoints(shape:getPoints())}
                    for i,p in ipairs(points) do points[i] = floor(p) end
                    Draw.line(body:getWorldPoints(shape:getPoints()))
                end
            end
        end;
        drawDebug = function(world_name)
            world_name = world_name or '_default'
            if Physics.debug then
                world = worlds[world_name]
                for _, body in pairs(world:getBodies()) do
                    Draw.color(1,0,0,.8)
                    Physics.draw(body,'line')
                    Draw.color(1,0,0,.5)
                    Physics.draw(body)
                end
                Draw.color()
            end
        end;
    }
end

--HITBOX
Hitbox = nil
do
    local bump = blanke_require('bump')
    local world = bump.newWorld(40)
    local new_boxes = true

    local calcBounds = function(obj)
        local repos = false
        if obj.is_entity then
            repos = obj:_checkForAnimHitbox()
        else 
            obj.align = 'center'
        end
        return  obj.alignx * abs(obj.scale * obj.scalex),
                obj.aligny * abs(obj.scale * obj.scaley),
                repos
    end
    local checkHitArea = function(obj)
        local left, top, repos = calcBounds(obj)
        local hb = obj.hitbox

        if type(hb) ~= 'table' then
            hb = {
                left = 0,
                top = 0,
                right = 0,
                bottom = 0
            }
        end

        hb.left = left
        hb.top = top

        if not obj.hasHitbox then 
            obj.hasHitbox = true
            new_boxes = true
            
            world:add(
                obj, obj.x - hb.left, obj.y - hb.top,
                abs(obj.width * obj.scale * obj.scalex) + hb.right, abs(obj.height * obj.scale * obj.scaley) + hb.bottom
            )
        end

        obj.hitbox = hb
        
        if repos then
            Hitbox.teleport(obj)
        end
        return obj.hitbox
    end

    Hitbox = {
        debug = false;
        default_reaction = 'static';

        add = function(obj)
            if not obj.tag then obj.tag = obj.classname or '' end
            if obj.x and obj.y and obj.width and obj.height then
                Game.checkAlign(obj)
                if obj.hasHitbox then
                    Hitbox.teleport(obj)
                else 
                    checkHitArea(obj)
                end
            end
        end;  
        adjust = function(obj, left, top, right, bottom) 
            if obj and obj.hasHitbox then 
                local hb = checkHitArea(obj)
                if left then hb.left = hb.left + left end 
                if top then hb.top = hb.top + top end 
                if right then hb.right = hb.right + right end 
                if bottom then hb.bottom = hb.bottom + bottom end
                Hitbox.teleport(obj)
            end
        end;
        -- ignore collisions
        teleport = function(obj, x, y)
            if obj and not obj.destroyed and obj.hasHitbox then
                local hb = checkHitArea(obj)                
                world:update(obj, 
                    obj.x - hb.left, obj.y - hb.top,
                    abs(obj.width * obj.scale * obj.scalex) + hb.right, abs(obj.height * obj.scale * obj.scaley) + hb.bottom
                )
            end
        end;
        at = function(x, y, tag)
            local ret = {}
            --[[
            local shapes = HC.shapesAt(x,y)
            for s in pairs(shapes) do 
                if not tag or s.parent.tag == tag then 
                    table.insert(s)
                end
            end]]
            return ret
        end;
        move = function(obj)
            if obj and not obj.destroyed and obj.hasHitbox then
                local filter = function(_obj, other)
                    local ret = _obj.reaction or Hitbox.default_reaction
                    if _obj.reactions and _obj.reactions[other.tag] then ret = _obj.reactions[other.tag] else
                        if _obj.reaction then ret = _obj.reaction end 
                    end
                    if other.reactions and other.reactions[_obj.tag] then ret = other.reactions[_obj.tag] else 
                        if other.reaction then ret = other.reaction end
                    end
                    if _obj.filter then ret = _obj:filter(other) end	

                    return ret
                end
                -- move the hitbox
                local hb = checkHitArea(obj)

                local offx = hb.left
                local offy = hb.top 

                local new_x, new_y, cols, len = world:move(obj, 
                    obj.x - offx,
                    obj.y - offy, 
                    filter)
                if obj.destroyed then return end
                obj.x = new_x + offx
                obj.y = new_y + offy
                local swap = function(t, key1, key2)
                    local temp = t[key1]
                    t[key1] = t[key2]
                    t[key2] = temp
                end
                if obj.collision and len > 0 then
                    for i=1,len do
                        if not obj or obj.destroyed then return end
                        obj:collision(cols[i])
                        local info = cols[i]
                        local other = info.other
                        swap(info, 'item', 'other')
                        swap(info, 'itemRect', 'otherRect')
                        if other and not other.destroyed and other.collision then other:collision(info) end
                    end
                end
            end
        end;
        remove = function(obj)
            if obj and not obj.destroyed and obj.hasHitbox then 
                obj.hasHitbox = false
                world:remove(obj)
                new_boxes = true 
            end 
        end;
        draw = function()
            if Hitbox.debug then
                if new_boxes then 
                    new_boxes = false
                    hb_items, hb_len = world:getItems()
                end
                for _,i in ipairs(hb_items) do
                    if i.hasHitbox and not i.destroyed then
                        Draw.color(i.hitboxColor or {1,0,0,0.9})
                        Draw.rect('line',world:getRect(i))
                        Draw.color(i.hitboxColor or {1,0,0,0.25})
                        Draw.rect('fill',world:getRect(i))
                    end
                end
                Draw.color()
            end
        end
    }
end

--STATE
State = nil
do 
    local states = {}
    local stop_states = {}
    local stateCB = function(name, fn_name, ...)
        local state = states[name]
        assert(state, "State '"..name.."' not found")
        if state then 
            state.running = true
            State.curr_state = name
            if state.callbacks[fn_name] then state.callbacks[fn_name](...) end
            State.curr_state = nil
            return state
        end
    end
    local stop_states, start_states
    local stateStart = function(name)
        local state = states[name]
        assert(state, "State '"..name.."' not found")
        if state and not state.running then
            stateCB(name, 'enter')
        end
    end
    local stateStop = function(name)
        local state = states[name]
        assert(state, "State '"..name.."' not found")
        if state and state.running then
            state = stateCB(name, 'leave')
            local objs = state.objects
            state.objects = {}
            for _,obj in ipairs(objs) do 
                if obj then obj:destroy() end 
            end
            state.running = false
        end
    end
    State = class {
        curr_state = nil;
        init = function(self, name, cbs)
            if states[name] then return nil end
            self.name = name
            self.callbacks = cbs
            self.objects = {}
            self.running = false
            states[name] = self
        end,
        addObject = function(obj)
            local state = states[State.curr_state]
            if state then 
                table.insert(state.objects, obj)
            end 
        end,
        update = function(name, dt)
            for name, state in pairs(states) do 
                if state.running then 
                    stateCB(name, 'update', dt)
                end
            end
        end,
        draw = function()
            for name, state in pairs(states) do 
                if state.running then 
                    Draw.push()
                    stateCB(name, 'draw')
                    Draw.pop()
                end
            end
        end,
        start = function(name)
            if name then 
                if not start_states then start_states = {} end
                start_states[name] = true
            end
        end,
        stop = function(name) 
            if stop_states == 'all' then return end
            if not name then stop_states = 'all' else
                if not stop_states then stop_states = {} end
                stop_states[name] = true
            end
        end,
        restart = function(name)
            if name then 
                stateStop(name)
                stateStart(name)
            end
        end,
        _check = function()
            if stop_states == 'all' then 
                for name,_ in pairs(states) do 
                    stateStop(name)
                end
            elseif stop_states then 
                for name,_ in pairs(stop_states) do 
                    stateStop(name)
                end
            end
            if start_states then 
                for name,_ in pairs(start_states) do 
                    stateStart(name)
                end
                Game.sortDrawables()
            end
            stop_states = nil
            start_states = nil
        end
    }
end 

--NET
Net = nil
do
    local client
    local leader = false
    local net_objects = {}

    local triggerSyncFn = function(obj, data, spawning)
        if obj.netSync then 
            return obj:netSync(data, spawning) or 0
        end
        return 0
    end

    local destroyObj = function(clientid, objid)
        local obj = net_objects[clientid][objid] 
        if obj then 
            if not obj.net_persistent then 
                obj:destroy()
                net_objects[clientid][objid] = nil
            end
        end
    end

    local destroyNetObjects = function(clientid, _objid)
        if net_objects[clientid] then 
            if _objid then 
                destroyObj(clientid, _objid)
            else
                for objid, obj in pairs(net_objects[clientid]) do 
                    destroyObj(clientid, objid)
                end
            end
            net_objects[clientid] = nil
        end
    end

    local sendData = function(data)
        if client then 
            client:publish({
                message = {
                    type="data",
                    timestamp = love.timer.getTime(),
                    clientid=Net.id,
                    data=data,
                    room=Net.room
                }
            })
        end
    end 

    local sendNetEvent = function(event, data)
        if client then 
            client:publish({
                message = {
                    type="netevent",
                    timestamp = love.timer.getTime(),
                    event=event,
                    data=data,
                    room=Net.room
                }
            })
        end
    end

    local storeNetObject = function(clientid, obj, objid)
        objid = objid or obj.net_id or uuid()
        if not net_objects[clientid] then net_objects[clientid] = {} end 
        net_objects[clientid][objid] = obj
    end

    local onReceive = function(data)
        local netdata = data.data
        if data.type == "netevent" then 
            if data.event == "getID" then 
                if Net.id then 
                    net_objects[Net.id] = nil
                end
                Net.id = data.info.id
                leader = data.info.is_leader
                net_objects[Net.id] = {}
                Signal.emit('net.ready')
            end
            if data.event == "set.leader" and data.info == Net.id then 
                leader = true
            end
            if data.event == "client.connect" and data.clientid ~= Net.id then 
                Signal.emit('net.connect', data.clientid)
                -- get new client up to speed with net objects
                Net.syncAll(data.clientid)
            end
            if data.event == "client.disconnect" then 
                Signal.emit('net.disconnect', data.clientid)
                destroyNetObjects(data.clientid)
            end
            if data.event == "obj.sync" and netdata.clientid ~= Net.id then 
                local obj = (net_objects[netdata.clientid] or {})[netdata.objid]
                if obj then 
                    for prop, val in pairs(netdata.props) do 
                        obj[prop] = val
                    end
                end
            end
            if data.event == "obj.spawn" and netdata.clientid ~= Net.id then
                netdata.args.net_obj = true
                local obj = Game.spawn(netdata.classname, netdata.args)
                storeNetObject(netdata.clientid, obj, netdata.args.net_id)
            end
            if data.event == "obj.syncAll" and netdata.targetid == Net.id then 
                for clientid, objs in pairs(netdata.sync_objs) do 
                    for objid, props in pairs(objs) do 
                        local obj = Game.spawn(props.classname, props)
                        storeNetObject(clientid, obj, objid)
                    end
                end
            end
            if data.event == "obj.destroy" and netdata.clientid ~= Net.id then 
                destroyObj(netdata.clientid, netdata.objid)
            end
        elseif data.type == "data" and netdata.clientid ~= Net.id then
            Signal.emit('net.data', netdata, data)
        end
    end

    local onFail = function()
        Signal.emit('net.fail')
    end

    local prepNetObject = function(obj)
        obj.net = true
        if not obj._net_last_val then 
            -- setup object for net syncing
            obj._net_last_val = {}
            if not net_objects[Net.id] then net_objects[Net.id] = {} end
            if not obj.net_id then obj.net_id = uuid() end
            net_objects[Net.id][obj.net_id] = obj
        end
    end

    Signal.on('update', function(dt)
        if client then client:enterFrame() end
    end)

    Net = {
        address='localhost',
        port=8080,
        room=1,
        id='0',
        connect = function(address,port)
            Net.address = address or Net.address
            Net.port = port or Net.port
            client = noobhub.new({ server=Net.address, port=Net.port })
            if client then 
                client:subscribe({
                    channel = "room"..tostring(Net.room),
                    callback = onReceive,
                    cb_reconnect = onFail
                })
            else 
                print("failed connecting to "..Net.address..":"..Net.port)
                onFail()
            end
        end,
        disconnect = function()
            if client then 
                client:unsubscribe()
                client = nil
                leader = false
            end
        end,
        connected = function() return client ~= nil end,
        send = function(data)
            if not client then return end
            sendData(data)
        end,
        on = function(event, fn)
            Signal.on('net.'..event, fn)
        end,
        spawn = function(obj, args)
            if not client then return end
            prepNetObject(obj)
            -- trash function arguments
            args = args or {}
            for prop, val in pairs(args) do
                if type(val) == 'function' then args[prop] = nil end
            end
            triggerSyncFn(obj, args, true)
            args.net_id = obj.net_id
            sendNetEvent('obj.spawn', {
                clientid = Net.id,
                classname = obj.classname,
                args = args
            })
            Net.sync(obj, nil, true)
        end,
        destroy = function(obj)
            if obj.net and not obj.net_obj and not obj.net_persistent then 
                sendNetEvent('obj.destroy', {
                    clientid = Net.id,
                    objid = obj.net_id
                })
            end
        end,
        -- only to be used with class instances. will not sync functions?/table data (TODO: sync functions too?)
        sync = function(obj, vars, spawning) 
            if not client or not obj or not (obj.net or obj.net_obj) then return end
            if not obj then 
                for objid, obj in pairs(net_objects[Net.id]) do 
                    Net.sync(obj)
                end
                return
            end
            prepNetObject(obj)
            local net_vars = vars or obj.net_vars or {}
            if spawning then 
                net_vars = vars or obj.net_spawn_vars or {}
            end
            if not obj.net_obj and #net_vars > 0 then 
                -- get vars to sync
                local sync_data = {}
                local len = 0
                for _, prop in ipairs(net_vars) do 
                    if obj[prop] ~= obj._net_last_val[prop] then 
                        obj._net_last_val[prop] = obj[prop]
                        sync_data[prop] = obj[prop]
                        len = len + 1
                    end
                end
                len = len + triggerSyncFn(obj, sync_data, spawning)
                -- sync vars
                if len > 0 then
                    sendNetEvent('obj.sync', {
                        clientid = Net.id,
                        objid = obj.net_id,
                        props = sync_data
                    })
                end
            end
        end,
        syncAll = function(targetid)
            if not client then return end
            if leader then 
                local sync_objs = {}
                for clientid, objs in pairs(net_objects) do 
                    sync_objs[clientid] = {}
                    for objid, obj in pairs(objs) do
                        if obj and not obj.destroyed then  
                            sync_objs[clientid][objid] = { classname=obj.classname, net_id=objid, net_obj=true }
                            for _,prop in ipairs(obj.net_spawn_vars) do 
                                sync_objs[clientid][objid][prop] = obj[prop]
                            end
                            triggerSyncFn(obj, sync_objs[clientid][objid], true)
                        end
                    end
                end
                sendNetEvent('obj.syncAll', {
                    clientid = Net.id,
                    targetid = targetid,
                    sync_objs = sync_objs
                })
            end
        end,
        ip = function()
            local s = socket.udp()
            s:setpeername("74.125.115.104",80)
            local ip, _ = s:getsockname()
            return ip
        end
    }
end

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
        width = 1;
        height = 1;
        os = nil;
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

--TIMER
Timer = nil 
do 
    local l_after = {}
    local l_every = {}
    local addTimer = function(t, fn, tbl)
        local id = uuid()
        local timer = {
            fn = fn,
            duration = t,
            t = t,
            iteration = 1,
            paused = false,
            destroy = function()
                tbl[id] = nil
            end
        }
        tbl[id] = timer
        return timer
    end

    Timer = {
        update = function(dt) 
            -- after
            for id,timer in pairs(l_after) do 
                if not timer.paused then
                    timer.t = timer.t - dt 
                    if timer.t < 0 then 
                        if timer.fn and timer.fn(timer) then 
                            -- another one (restart timer)
                            timer.t = timer.duration
                            timer.iteration = timer.iteration + 1
                        else 
                            -- destroy it
                            timer.destroy()
                        end
                    end
                end
            end
            -- every
            for id,timer in pairs(l_every) do
                if not timer.paused then 
                    timer.t = timer.t - dt 
                    if timer.t < 0 then 
                        if not timer.fn or timer.fn(timer) then 
                            -- destroy it!
                            timer.destroy()
                        else
                            -- restart timer
                            timer.t = timer.duration
                            timer.iteration = timer.iteration + 1
                        end
                    end
                end
            end
        end,
        after = function(t, fn) 
            addTimer(t, fn, l_after)
        end,
        every = function(t, fn) 
            addTimer(t, fn, l_every)
        end
    }
end

--FEATURE
Feature = {}
do
    local enabled = {}
    Feature = callable {
        -- returns true if feature is enabled
        __call = function(self, name)
            return enabled[name] ~= false
        end,
        disable = function(...)
            local flist = {...}
            for _, f in ipairs(flist) do 
                print('disabling',f)
                enabled[f] = false 
            end
        end,
        enable = function(...)
            local flist = {...}
            for _, f in ipairs(flist) do 
                enabled[f] = true 
            end
        end
    }
end

--BLANKE
Blanke = nil
do 
    local iterate = function(t, test_val, fn) 
        local len = #t
        local offset = 0
        local reorder = false
        for o=1,len do
            local obj = t[o]
            if obj then 
                if obj.destroyed or not obj[test_val] then 
                    offset = offset + 1
                else
                    if (obj._last_z == nil and obj.z) or obj._last_z ~= obj.z then 
                        obj._last_z = obj.z
                        reorder = true 
                    end
                    fn(obj, o)
                    t[o] = nil
                    t[o - offset] = obj
                end
            end
        end
        return reorder
    end

    local update_obj = Game.updateObject
    local stack = Draw.stack

    Blanke = {
        config = {};
        game_canvas = nil;
        loaded = false;
        scale = 1;
        padx = 0;
        pady = 0;
        load = function()
            if not Blanke.loaded then
                love.joystick.loadGamepadMappings('gamecontrollerdb.txt')
                Blanke.loaded = true
            end
        end;
        addUpdatable = function(obj)
            obj.updatable = true
            table.insert(Game.updatables, obj)
        end;
        addDrawable = function(obj)
            obj.drawable = true
            table.insert(Game.drawables, obj)
        end;
        iterUpdate = function(t, dt)
            iterate(t, 'updatable', function(obj)
                if obj.skip_update ~= true and obj.pause ~= true and obj._update then
                    update_obj(dt, obj)
                end
            end)
        end;
        iterDraw = function(t, override_drawable)
            local reorder_drawables = iterate(t, 'drawable', function(obj)
                if obj.visible == true and obj.skip_draw ~= true and (override_drawable or obj.drawable == true) and obj.draw ~= false then
                    local obj_draw = obj._draw
                    stack(function()
                        if obj_draw then obj_draw(obj) end
                    end)
                end
            end)
    
            if reorder_drawables then 
                Game.sortDrawables()
            end
        end;
        --blanke.update
        update = function(dt)
            Game.update(dt)
        end; 
        --blanke.draw   
        draw = function()
            Draw.origin()
            local actual_draw = function()
                Blanke.iterDraw(Game.drawables)
                State.draw()
                if Game.options.postdraw then Game.options.postdraw() end
                Physics.drawDebug()
                Hitbox.draw()
            end

            local _drawGame = function()
                Draw{
                    {'push'},
                    {'color',Game.options.background_color},
                    {'rect','fill',0,0,Game.width,Game.height},
                    {'pop'}
                }
                if Camera.count() > 0 then
                    Camera.useAll(actual_draw)
                else 
                    actual_draw()
                end
            end
        
            local _draw = function()
                Game.options.draw(function()
                    if Game.effect then
                        Game.effect:draw(_drawGame)
                    else 
                        _drawGame()
                    end
                end)
            end

            Blanke.game_canvas:drawTo(_draw)
            
            Draw{
                {'push'},
                {'color','black'},
                {'rect','fill',0,0,Window.width,Window.height},
                {'pop'}
            }

            if Game.options.scale == true then
                Blanke.game_canvas.x, Blanke.game_canvas.y = Blanke.padx, Blanke.pady
                Blanke.game_canvas.scale = Blanke.scale
                Blanke.game_canvas:draw()
            
            else 
                Blanke.game_canvas:draw()
            end
        end;
        keypressed = function(key, scancode, isrepeat)
            Input.press(key, {scancode=scancode, isrepeat=isrepeat})
        end;
        keyreleased = function(key, scancode)
            Input.release(key, {scancode=scancode})
        end;
        mousepressed = function(x, y, button, istouch, presses) 
            Input.press('mouse', {x=x, y=y, button=button, istouch=istouch, presses=presses})
            Input.press('mouse'..tostring(button), {x=x, y=y, button=button, istouch=istouch, presses=presses})
        end;
        mousereleased = function(x, y, button, istouch, presses) 
            Input.press('mouse', {x=x, y=y, button=button, istouch=istouch, presses=presses})
            Input.release('mouse'..tostring(button), {x=x, y=y, button=button, istouch=istouch, presses=presses})
        end;
        gamepadpressed = function(joystick, button)
            Input.press('gp.'..button, {joystick=joystick})
        end;
        gamepadreleased = function(joystick, button)
            Input.release('gp.'..button, {joystick=joystick})
        end;
        joystickadded = function(joystick)
            Signal.emit("joystickadded", joystick)
            refreshJoystickList()
        end;
        joystickremoved = function(joystick)
            Signal.emit("joystickremoved", joystick)
            refreshJoystickList()
        end;
        gamepadaxis = function(joystick, axis, value)
            Input.store('gp.'..axis, {joystick=joystick, value=value})
        end;
        touchpressed = function(id, x, y, dx, dy, pressure)
            Input.press('touch', {id=id, x=x, y=y, dx=dx, dy=dy, pressure=pressure})
        end;
        touchreleased = function(id, x, y, dx, dy, pressure)
            Input.release('touch', {id=id, x=x, y=y, dx=dx, dy=dy, pressure=pressure})
        end;
    }
end

Signal.emit('__main')

love.load = function() 
    if do_profiling then
        love.profiler = blanke_require('profile')
    end

    Blanke.load() 
end
love.frame = 0

local update = function(dt)
    if do_profiling then 
        love.profiler.start()
    end

    Blanke.update(dt)

    if do_profiling then
        love.frame = love.frame + 1
        if love.frame > 60 then 
            love.profiler.stop()
            love.report = love.profiler.report(do_profiling)
            print(love.report)
        end
    end

end

do
    local dt = 0
    local accumulator = 0
    local fixed_dt
    love.update = function(dt) 
        fixed_dt = Game.options.fps and 1/Game.options.fps or nil
        if fixed_dt == nil then 
            update(dt)
        else 
            accumulator = accumulator + dt
            while accumulator >= fixed_dt do
                update(fixed_dt)
                accumulator = accumulator - fixed_dt
            end
        end
    end
end
love.draw = function() 
    Blanke.draw() 
    Draw.push()
    if do_profiling then
        love.graphics.setColor(1,1,1,0.8)
        love.graphics.rectangle('fill',0,0,Window.width,Window.height)
        love.graphics.setColor(unpack(profiling_color))
        love.graphics.print(love.report or "Please wait...")
    end
    Draw.pop()
end
love.resize = function(w, h) Game.updateWinSize() end
love.keypressed = function(key, scancode, isrepeat) Blanke.keypressed(key, scancode, isrepeat) end
love.keyreleased = function(key, scancode) Blanke.keyreleased(key, scancode) end
love.mousepressed = function(x, y, button, istouch, presses) Blanke.mousepressed(x, y, button, istouch, presses) end
love.mousereleased = function(x, y, button, istouch, presses) Blanke.mousereleased(x, y, button, istouch, presses) end
love.gamepadpressed = function(joystick, button) Blanke.gamepadpressed(joystick, button) end 
love.gamepadreleased = function(joystick, button) Blanke.gamepadreleased(joystick, button) end 
love.joystickadded = function(joystick) Blanke.joystickadded(joystick) end 
love.joystickremoved = function(joystick) Blanke.joystickremoved(joystick) end
love.gamepadaxis = function(joystick, axis, value) Blanke.gamepadaxis(joystick, axis, value) end
love.touchpressed = function(id, x, y, dx, dy, pressure) Blanke.touchpressed(id, x, y, dx, dy, pressure) end
love.touchreleased = function(id, x, y, dx, dy, pressure) Blanke.touchreleased(id, x, y, dx, dy, pressure) end
