-- TODO rework Image to autobatch
-- TODO 9-slicing
local _NAME = ...
local blanke_require = function(r)
    return require('blanke.'..r)
end

math.randomseed(os.time())
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

local tbl_to_str
tbl_to_str = function(t, str)
    local empty = true
    str = str or ''
    str = str .. "["
    for i = 1, #t, 1 do
        if i ~= 1 then 
            str = str .. ','
        end 
        if type(t[i]) == "table" then 
            str = str .. tbl_to_str(t[i], str)
        else 
            str = str .. tostring(t[i])
        end 
    end
    str = str .. "]"
    return str
end

local socket = require("socket")
callable = function(t)
    if t.__ then
        for _, mm in ipairs(t) do t['__'..mm] = t.__[mm] end
    end
    return setmetatable(t, { __call = t.__call })
end

-- blanke_require("ecs")

memoize = nil
do
    local mem_cache = {}
    setmetatable(mem_cache, {__mode = "kv"})
    memoize = function(f, cache)
        -- default cache or user-given cache?
        cache = cache or mem_cache
        if not cache[f] then 
            cache[f] = {}
        end 
        cache = cache[f]
        return function(...)
            local args = {...}
            local cache_str = '<no-args>'
            local found_args = false
            for i, v in ipairs(args) do
                if v ~= nil then 
                    if not found_args then 
                        found_args = true 
                        cache_str = ''
                    end

                    if i ~= 1 then 
                        cache_str = cache_str .. '~'
                    end 
                    if type(v) == "table" then
                        cache_str = cache_str .. tbl_to_str(v)
                    else
                        cache_str = cache_str .. tostring(v)
                    end
                end
            end 
            -- retrieve cached value?
            local ret = cache[cache_str]
            if not ret then
                -- not cached yet
                ret = { f(unpack(args)) }
                cache[cache_str] = ret 
                -- print('store',cache_str,'as',unpack(ret))
            end
            return unpack(ret)
        end
    end
end 

-- is given version greater than or equal to current LoVE version?
local ge_version = function(major, minor, rev)
    if major and major > Game.love_version[1] then return false end
    if minor and minor > Game.love_version[2] then return false end
    if rev and rev > Game.love_version[3] then return false end
    return true
end

--TABLE
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
table.every = function (t, fn)
    for k,v in pairs(t) do if fn ~= nil and not fn(v, k) or not v then return false end end
    return true
end
table.some = function (t, fn)
    for k,v in pairs(t) do if fn ~= nil and fn(v, k) or v then return true end end
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
table.randomWeighted = function(t)
    local r = Math.random(0,100)
end
table.includes = function(t, v)
    for i = 1,#t do if t[i] == v then return true end end
    return false
end
table.join = function(t, sep, nil_str)
    local str = ''
    for i = 1, #t do
        str = str .. tostring(t[i] ~= nil and t[i] or (nil_str and 'nil'))
        if i ~= #t then
            str = str .. tostring(sep)
        end
    end
    return str
end
--STRING
function string:starts(start)
   return string.sub(self,1,string.len(start))==start
end
function string:contains(q)
    return string.match(tostring(self), tostring(q)) ~= nil
end
function string:count(str)
    local _, count = string.gsub(self, str, "")
    return count
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
string.expand = memoize(function(self, ...)
    -- version: 0.0.1
    -- code: Ketmar // Avalon Group
    -- public domain

    -- expand $var and ${var} in string
    -- ${var} can call Lua functions: ${string.rep(' ', 10)}
    -- `$' can be screened with `\'
    -- `...': args for $<number>
    -- if `...' is just a one table -- take it as args
    function ExpandVars (s, ...)
      local args = {...};
      args = #args == 1 and type(args[1]) == "table" and args[1] or args;
      -- return true if there was an expansion
      local function DoExpand (iscode)
        local was = false;
        local mask = iscode and "()%$(%b{})" or "()%$([%a%d_]*)";
        local drepl = iscode and "\\$" or "\\\\$";
        s = s:gsub(mask, function (pos, code)
          if s:sub(pos-1, pos-1) == "\\" then return "$"..code;
          else was = true; local v, err;
            if iscode then code = code:sub(2, -2);
            else local n = tonumber(code);
              if n then v = args[n]; end;
            end;
            if not v then
              v, err = loadstring("return "..code); if not v then error(err); end;
              v = v();
            end;
            if v == nil then v = ""; end;
            v = tostring(v):gsub("%$", drepl);
            return v;
          end;
        end);
        if not (iscode or was) then s = s:gsub("\\%$", "$"); end;
        return was;
      end;

      repeat DoExpand(true); until not DoExpand(false);
      return s;
    end;
    return ExpandVars(self, ...)
end)
--math
local sin, cos, rad, deg, abs, min, max = math.sin, math.cos, math.rad, math.deg, math.abs, math.min, math.max
local floor = function(x) return math.floor(x+0.5) end
Math = {}
do
    for name, fn in pairs(math) do Math[name] = function(...) return fn(...) end end

    local clamp = function(x, _min, _max) return min(_max, max(_min, x)) end

    Math.clamp = clamp
    Math.sign = function(x) return (x < 0) and -1 or 1 end
    Math.seed = function(l,h) if l then love.math.setRandomSeed(l,h) else return love.math.getRandomSeed() end end
    Math.random = function(...) return love.math.random(...) end
    Math.indexTo2d = function(i, col) return math.floor((i-1)%col)+1, math.floor((i-1)/col)+1 end
    Math.getXY = memoize(function(angle, dist) return dist * cos(angle), dist * sin(angle) end)
    Math.distance = memoize(function(x1,y1,x2,y2) return math.sqrt( (x2-x1)^2 + (y2-y1)^2 ) end)
    Math.lerp = function(a,b,t) 
        local r = a * (1-t) + b * t
        if a < b then return clamp(r, a, b) 
        else return clamp(r, b, a) end
    end 
    Math.prel = function(a,b,v) -- returns what percent v is between a and b
        if v >= b then return 1
        elseif v <= a then return 0
        else return (v - a) / (b - a) end
    end
    Math.sinusoidal = function(min, max, spd, percent) return Math.lerp(min, max, Math.prel(-1, 1, math.cos(Math.lerp(0,math.pi/2,percent or 0) + (Game.time * (spd or 1)) )) ) end
    --  return min + -math.cos(Math.lerp(0,math.pi/2,off or 0) + (Game.time * spd)) * ((max - min)/2) + ((max - min)/2) end
    Math.angle = memoize(function(x1, y1, x2, y2) return math.atan2((y2-y1), (x2-x1)) end)
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
sort = nil 
do 
    sort = function(t, key, default)
        if #t == 0 then return end
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
            if a[key] == nil then a[key] = default end
            if b[key] == nil then b[key] = default end
            return a[key] < b[key]
        end)
    end
end

iterate = function(t, fn)
    if not t then return end
    local len = #t
    local offset = 0
    local removals = {}
    for o=1,len do
        local obj = t[o]
        if obj then
            if fn(obj, o) == true then
                table.insert(removals, o)
            end
        end
    end
    if #removals > 0 then
        for i = #removals, 1, -1 do
            table.remove(t, removals[i])
        end
    end
end

local nonzero_z = false
local iterateEntities = function(t, test_val, fn)
    if not t then return end
    local len = #t
    local offset = 0
    local removals = {}
    for o=1,len do
        local obj = t[o]
        if obj then
            if obj.destroyed or not obj[test_val] or fn(obj, o) == true then
                table.insert(removals, o)
            elseif obj._last_z ~= obj.z then
                obj._last_z = obj.z
                reorder = true
                Game.sortDrawables()
            end
        end
    end
    if #removals > 0 then
        for i = #removals, 1, -1 do
            table.remove(t, removals[i])
        end
    end

    return reorder
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
local lua_print = print
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
        end,
        -- (str, num, ['data'/'string']) -> contents, size
        open = function(path, mode)
            return love.filesystem.newFile(path, mode)
        end,
        openURL = function(path)
            return love.system.openURL(path)
        end
    }
end

--SAVE
Save = nil
do
    local f_save
    local _load = function()
        if not f_save then f_save = FS.open('save.json') end
        f_save:open('r')
        -- Save.data = f_save:read()
        local data, size = f_save:read()
        if data and size > 0 then
            Save.data = json.decode(data)
        end
        f_save:close()
    end

    Save = {
        data = {},
        dir = function() return love.filesystem.getSaveDirectory() end,
        update = function(new_data)
            if new_data then table.update(Save.data, new_data) end
            Save.save()
        end,
        remove = function(...)
            local path = {...}
            local data = Save.data
            for i, p in ipairs(path) do
                if type(data) == 'table' then
                    if i == #path then
                        data[p] = nil
                    else
                        data = data[p]
                    end
                end
            end
        end,
        load = function()
            _load()
            if not Save.data then Save.data = {} end
        end,
        save = function()
            if f_save and table.len(Save.data) > 0 then
                f_save:open('w')
                f_save:write(json.encode(Save.data or {}))
                f_save:close()
            end
        end
    }
end

--SIGNAL
Signal = nil
do
    local function ends_with(str, ending)
       return ending == "" or str:sub(-#ending) == ending
    end
    local fns = {}

    Signal = {
        emit = function(event, ...)
            local args = {...}
            local big_ret = {}
            if fns[event] then
                iterate(fns[event], function(fn, i)
                    local ret = fn(unpack(args))
                    if ret then table.insert(big_ret, ret) end
                    return ret == true
                end)
            end
            return big_ret
        end,
        on = function(event, fn)
            if not fns[event] then fns[event] = {} end
            table.insert(fns[event], fn)
            return fn
        end,
        off = function(event, fn)
            if fns[event] then
                iterate(fns[event], function(_fn)
                    return fn == _fn
                end)
            end
        end
    }
end

--GAME
Game = nil
do
    local skip_tf = false
    local objects = {}

    local draw_obj = function(lobj, props, skip_tf, is_fn)
        Game.checkAlign(props)

        local x, y = floor(props.x), floor(props.y)
        local scalex, scaley = props.scalex * props.scale, props.scaley * props.scale
        local ax, ay = (props.alignx + props.offx) * scalex, (props.aligny + props.offy) * scaley
        local angle, shearx, sheary = props.angle, props.shearx, props.sheary

        local tform = props._draw_transform
        if not tform then
            props._draw_transform = love.math.newTransform()
            tform = props._draw_transform
        end

        tform:reset()
        tform:translate(x,y)
        
        if is_fn then
            tform:scale(scalex, scaley)
            tform:rotate(props.angle)
            tform:shear(props.shearx, props.sheary)
        end

        if not skip_tf then
            love.graphics.applyTransform(props._draw_transform)
        end
        if is_fn then
            lobj(props)
        else
            if props.quad then
                love.graphics.draw(lobj, props.quad, 0,0,0, scalex, scaley, ax, ay, shearx, sheary)
            else
                love.graphics.draw(lobj, 0,0,0, scalex, scaley, ax, ay, shearx, sheary)
            end
        end
    end

    local draw = function(props, lobj, is_fn)
        local parent = props.parent or props

        last_blend = nil
        if props.blendmode then
            last_blend = love.graphics.getBlendMode()
            love.graphics.setBlendMode(unpack(props.blendmode)) 
        end

        Draw.push()
        if props.mesh and props.mesh.vertices then
            local mesh_canvas = CanvasStack:new()
            local mesh_str = (props.mesh.mode or 'fan')..'.'..(props.mesh.usage or 'dynamic')
            local mesh = Cache.get('mesh', mesh_str, function(key)
                return love.graphics.newMesh(props.mesh.vertices, props.mesh.mode or 'fan', props.mesh.usage or 'dynamic')
            end)
            skip_tf = true
            mesh_canvas.value:drawTo(function() draw_obj(lobj, props, skip_tf, is_fn) end)
            mesh:setTexture(mesh_canvas.value) -- yes twice (since it's a canvasstack)
            love.graphics.draw(mesh)
            CanvasStack:release(mesh_canvas)
            skip_tf = false
        else
            draw_obj(lobj, props, skip_tf, is_fn)
        end

        if props.debug then
            local lax, lay = 0,0
            local rax, ray = abs(props.alignx), abs(props.aligny)

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
        love.graphics.applyTransform(props._draw_transform:inverse())
        Draw.pop()

        if last_blend then
            love.graphics.setBlendMode(last_blend)
        end
    end
    Game = callable {
        options = {
            res =           'assets',
            scripts =       {},
            filter =        'linear',
            vsync =         'on',
            auto_require =  true,
            background_color = 'black',
            window_flags = {},
            fps =           60,
            round_pixels =  false,

            auto_draw =     true,
            scale =         true,
            effect =        nil,

            load =          function() end,
            draw =          function(d) d() end,
            postdraw =      nil,
            update =        function(dt) end,
        };
        config = {};
        all_objects = {};
        updatables = {};
        drawables = {};
        restarting = false;
        width = 0;
        height = 0;
        time = 0;
        love_version = {0,0,0};

        loaded = {
            all = false,
            settings = false,
            scripts = false,
            assets = false
        };

        __call = function(self,args)
            table.update(Game.options, args)
            return Game
        end;

        updateWinSize = function(w,h)
            Window.width, Window.height, flags = love.window.getMode()
            if w and h then Window.width, Window.height = w, h end
            if not Window.width then Window.width = Game.width end
            if not Window.height then Window.height = Game.height end
            
            if Window.os == 'web' then
                Game.width, Game.height = Window.width, Window.height
            end
            if not Game.options.scale then
                Game.width, Game.height = Window.width, Window.height
                if Blanke.game_canvas then Blanke.game_canvas:resize(Game.width, Game.height) end
            end
        end;

        load = function(which)
            if Game.restarting then
                Signal.emit("Game.restart")
            end

            if not Game.loaded.settings and which == "settings" or not which then
                Game.time = 0
                Game.love_version = {love.getVersion()}
                love.joystick.loadGamepadMappings('gamecontrollerdb.txt')

                -- load config.json
                local f_config = FS.open("config.json")
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
                if not Game.loaded.settings then
                    if not Game.restarting then
                        -- window size and flags
                        Game.options.window_flags = table.update({
                            borderless = Game.options.frameless,
                            resizable = Game.options.resizable,
                        }, Game.options.window_flags or {})

                        if Window.os ~= 'web' then
                            Window.setSize(Game.config.window_size)
                        end
                        Game.updateWinSize()
                    end
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
                end

                Save.load()
            end

            if not Game.loaded.assets and which == "assets" or not which then
                Draw.setFont('04B_03.ttf', 16)
            end

            if not Game.loaded.scripts and which == "scripts" or not which then
                local scripts = Game.options.scripts or {}
                local no_user_scripts = (#scripts == 0)
                -- load plugins
                if Game.options.plugins then
                    for _,f in ipairs(Game.options.plugins) do
                        package.loaded['plugins.'..f] = nil
                        require('plugins.'..f)
                        -- table.insert(scripts,'lua/plugins/'..f..'/init.lua') -- table.insert(scripts,'plugins.'..f)
                    end
                end
                -- load scripts
                if Game.options.auto_require and no_user_scripts then
                    local load_folder
                    load_folder = function(path)
                        if path:starts("/.") then return end
                        files = FS.ls(path)

                        local dirs = {}

                        for _,f in ipairs(files) do
                            local file_path = path..'/'..f
                            if FS.extname(f) == 'lua' and not table.hasValue(scripts, file_path) then
                                table.insert(scripts, file_path) -- table.join(string.split(FS.removeExt(file_path), '/'),'.'))
                            end
                            local info = FS.info(file_path)
                            if info.type == 'directory' and file_path ~= '/dist' and file_path ~= '/lua' then
                                table.insert(dirs, file_path)
                            end
                        end

                        -- load directories
                        for _, d in ipairs(dirs) do
                            load_folder(d)
                        end
                    end
                    load_folder('')
                end

                for _,script in ipairs(scripts) do
                    if not script:contains('main.lua') and not script:contains('blanke/init.lua') then
                        local ok, chunk = pcall( love.filesystem.load, script )
                        if not ok then error(chunk) end
                        assert(chunk, "Script not found: "..script)
                        local ok2, result = pcall( chunk )
                        if not ok2 then error(result) end
                        -- require(script)
                    end
                end
            end

            if not Game.loaded.settings and which == "settings" or not which then
                -- fullscreen toggle
                Input.set({ _fs_toggle = { 'alt', 'enter' } }, {
                    combo = { '_fs_toggle' },
                    no_repeat = { '_fs_toggle' },
                })
                if Game.options.fullscreen == true and not Game.restarting then
                    Window.fullscreen(true)
                end
                -- effect
                if Game.options.effect then
                    Game.setEffect(unpack(Game.options.effect))
                end
                if Game.options.load then
                    Game.options.load()
                end
                -- round pixels
                if not Game.options.round_pixels then
                    floor = function(x) return x end
                end

                love.graphics.setBackgroundColor(1,1,1,0)

                Blanke.game_canvas = Canvas{auto_draw=false}
                Blanke.game_canvas.__ide_obj = true
            end

            -- is everything loaded?
            Game.loaded.all = true
            for k, v in pairs(Game.loaded) do
                if which == k or not which then
                    Game.loaded[k] = true
                end
                if k ~= 'all' and Game.loaded[k] == false then
                    Game.loaded.all = false
                end
            end

            if Game.loaded.all then
                Signal.emit("Game.load")

                if Game.options.initial_state then
                    State.start(Game.options.initial_state)
                end
            end

            if Game.restarting then
                Game.updateWinSize()
            end
            Signal.emit("Game.start")
        end;

        restart = function()
            State.stop()
            Timer.stop()
            Audio.stop()
            for _, obj in ipairs(Game.all_objects) do
                if obj then
                    obj:destroy()
                end
            end
            objects = {}
            Game.all_objects = {}
            Game.updatables = {}
            Game.drawables = {}
            Game.loaded = {
                all = false,
                settings = false,
                scripts = false,
                assets = false
            }

            Game.restarting = true
        end;

        forced_quit = false;
        quit = function(force, status)
            Game.forced_quit = force
            love.event.quit(status)
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

        getObject = function(name)
            return objects[name]
        end;

        checkAlign = function(obj)
            local align = obj.align
            if obj.parent then align = obj.parent.align end

            local ax, ay = obj.alignx or 0, obj.aligny or 0

            if align and align ~= obj._last_align then
                obj._last_align = align

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
            end

            obj.alignx, obj.aligny = floor(ax), floor(ay)
        end;

        sortDrawables = function()
            Game.will_sort = true
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

        get = function(classname)
            return gobject_count[classname] or {}
        end;

        count = function(classname)
            return gobject_count[classname] or 0
        end;

        res = function(_type, file)
            if file:contains(Game.options.res.."/".._type) then 
                return file 
            end
            return Game.options.res.."/".._type.."/"..file
        end;

        setBackgroundColor = function(...)
            --love.graphics.setBackgroundColor(Draw.parseColor(...))
            Game.options.background_color = {Draw.parseColor(...)}
        end;

        update = function(dt)
            local dt_ms = dt * 1000

            Game.is_updating = true
            if Game.will_sort then
                Game.will_sort = nil
                sort(Game.drawables, 'z', 0)
            end

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
            Physics.update(dt)
            Timer.update(dt, dt_ms)
            if Game.options.update(dt) == true then return end
            -- World.update(dt) -- ecs
            Blanke.iterUpdate(Game.updatables, dt)
            State.update(dt)
            State._check()
            Signal.emit('update',dt,dt_ms)
            local key = Input.pressed('_fs_toggle')
            if key and key[1].count == 1 then
                Window.toggleFullscreen()
            end
            Input.keyCheck()
            Audio.update(dt)

            BFGround.update(dt)

            if Game.restarting then
                Game.load()
                Game.restarting = false
            end
            Game.is_updating = false
        end
    }
end

--GAMEOBJECT
GameObject = nil
do
    GameObject = class {
        init = function(self, args, spawn_args)
            args = copy(args) or {}
            spawn_args = copy(spawn_args) or {}
            self.uuid = uuid()
            self.x, self.y, self.z, self.angle, self.scalex, self.scaley, self.scale = 0, 0, 0, 0, 1, 1, 1
            self.offx, self.offy, self.shearx, self.sheary = 0, 0, 0, 0

            self.width = spawn_args.width or args.width or 0
            self.height = spawn_args.height or args.height or 0

            if self.width == 0 and self.height == 0 then
                self._preset_size = false
            else
                self._preset_size = true
            end

            if spawn_args.map_width and self.width == 0 then self.width = spawn_args.map_width end
            if spawn_args.map_height and self.height == 0 then self.height = spawn_args.map_height end

            self.align = nil
            self.blendmode = nil -- {'alpha'}
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
            self._last_z = self.z

            table.insert(Game.all_objects, self)

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
        use = function(self, other_obj, props)
            for _, prop in ipairs(props) do
                if other_obj[prop] then
                    self[prop] = other_obj[prop]
                end
            end
        end;
        on = function(self, name, fn)
            return Signal.on(self.uuid..":"..name, fn)
        end;
        off = function(self, name, fn)
            return Signal.off(self.uuid..":"..name, fn)
        end;
        emit = function(self, name, ...)
            return Signal.emit(self.uuid..":"..name, ...)
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
    init = function(self, settings)
        GameObject.init(self, {classname="Canvas"})
        settings = settings or {}
        local w, h = settings.w or Game.width, settings.h or Game.height
        if w <= 0 then w = Game.width end 
        if h <= 0 then h = Game.height end
        local auto_draw = settings.auto_draw
        settings.auto_draw = nil
        self.auto_clear = true
        self.width = w
        self.height = h
        self.canvas = love.graphics.newCanvas(self.width, self.height, settings)
        self.quad = love.graphics.newQuad(0,0,Game.width,Game.height,Game.width,Game.height)

        canv_len = canv_len + 1
        self.blendmode = {"alpha"}
        if auto_draw ~= false then
            self:addDrawable()
        end
    end;
    getDrawable = function(self)
        return self.canvas, { self.quad }
    end;
    reset = function(self)
        self.blendmode = {"alpha"}
        self.auto_clear = true
    end;
    _draw = function(self)
        if self.active then error("Cannot render Canvas to itself") end
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
            local last_canvas = love.graphics.getCanvas()
            love.graphics.setCanvas{self.canvas}
            --self.canvas:renderTo(function()
                self:prepare()
                obj()
            --end)
            love.graphics.setCanvas{last_canvas}
            self.active = false
        end)
    end;
}

--IMAGE
Image = nil
local getImage
do
    local animations = {}
    getImage = function(name)
        local new_img = Cache.get('Image', Game.res('image',name), function(key)
            return love.graphics.newImage(key)
        end)
        assert(new_img, "Image not found:\'"..name.."\'")
        return new_img
    end

    Image = GameObject:extend {
        info = function(name)
            if animations[name] then return animations[name]
            else
                return Cache.get('Image.info', Game.res('image',name), function(key)
                    local img = getImage(name)
                    return {
                        img = img,
                        width = img:getWidth(),
                        height = img:getHeight()
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
                local o = function(k, default)
                    assert(anim[k] or all_opt[k] or default, "'"..k.."' not found for "..file.." -> "..(anim.name or '?'))
                    return anim[k] or all_opt[k] or default
                end
                local quads, durations = {}, {}
                local fw, fh = img:getWidth() / o('cols'), img:getHeight() / o('rows')
                local offx, offy = o('offx', 0), o('offy', 0)
                -- calculate frame list
                local frame_list = {}
                local in_frames = o('frames', {'1-'..(o('cols')*o('rows'))})

                assert(not in_frames or type(in_frames) == "table", "Image.animation frames must be in array")
                for _,f in ipairs(in_frames) do
                    local f_type = type(f)
                    if f_type == 'number' then
                        table.insert(frame_list, f)
                    elseif f_type == 'string' then
                        local a,b = string.match(f,'%s*(%d+)%s*-%s*(%d+)%s*')
                        assert(a and b, "Invalid frames for '"..(anim.name or file).."' { "..(a or 'nil')..", "..(b or 'nil').." }")
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
                    duration=o('duration', 1),
                    durations=o('durations', {}),
                    quads=quads,
                    w=fw, h=fh, frame_size={fw,fh},
                    speed=o('speed', 1)
                }
            end
        end;
        init = function(self,args)
            -- animation?
            local anim_info = nil
            if type(args) == 'string' then
                if animations[args] then 
                    anim_info = animations[args]
                end
                args = anim_info or { file=args }
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
            end
            self.image = getImage(args.file)
            self.file = args.file
            
            GameObject.init(self, {classname="Image"}, args)

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
        getDrawable = function(self)
            if self.speed == 0 then 
                return self.image, { self.quads[self.frame_index] }
            else
                return self.image, self.quads or {}
            end
        end;
        updateSize = function(self)
            if self.animated then
                self.orig_width = self.animated.frame_size[1]
                self.orig_height = self.animated.frame_size[2]
                self.width, self.height = abs(self.animated.frame_size[1] * self.scalex * self.scale), abs(self.animated.frame_size[2] * self.scaley * self.scale)
            else
                self.orig_width = self.image:getWidth()
                self.orig_height = self.image:getHeight()
                self.width = abs(self.image:getWidth() * self.scalex * self.scale)
                self.height = abs(self.image:getHeight() * self.scaley * self.scale)
            end
        end;
        _update = function(self,dt)
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
        update = function(self,dt) self:_update(dt) end,
        _draw = function(self)
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
        self.xprevious = self.x 
        self.yprevious = self.y
        local diff_pos = (self.x ~= last_x or self.y ~= last_y)
        if self.destroyed then return end
        if self.gravity ~= 0 then
            local gravx, gravy = Math.getXY(self.gravity_direction, self.gravity)
            self.hspeed = self.hspeed + gravx
            self.vspeed = self.vspeed + gravy
        end

        -- moving x and y in separate steps solves 'sticking' issue (ty https://jonathanwhiting.com/tutorial/collision/)
        self.x = self.x + self.hspeed * dt
        Hitbox.move(self)
        self.y = self.y + self.vspeed * dt
        Hitbox.move(self)

        if self.update then self:update(dt) end
        self:_updateSize(anim)
        if self.body and self.body.is_physics then
            local new_x, new_y = self.body:getPosition()
            if self.x == last_x then self.x = new_x end
            if self.y == last_y then self.y = new_y end
            if diff_pos then
                self.body:setPosition(self.x, self.y)
            end
        end
        -- image/animation update
        if self.image then
            for name, img in pairs(self.imageList) do
                img:update(dt)
            end
        end
        if self.animation then
            for name, anim in pairs(self.animList) do
                anim:update(dt)
            end
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
            self.gravity_direction = rad(90)

            args = copy(args or {})
            spawn_args = copy(spawn_args or {})

            GameObject.init(self, args, spawn_args)

            if self.setup then
                self:setup(args, spawn_args)
            end

            self.imageList = {}
            self.animList = {}

            -- image
            if not args.images and args.image then 
                args.images = { args.image }
            end 
            if args.images then
                if type(args.images) == 'table' then
                    for _,img in ipairs(args.images) do
                        self.imageList[img] = Image{file=img, skip_update=true}
                        if not self.image then
                            self.image = img
                        end
                        self.imageList[img]._parent = self
                    end
                    self:_updateSize(self.imageList[self.image], true)
                else
                    self.imageList[args.images] = Image{file=args.images, skip_update=true}
                    self:_updateSize(self.imageList[self.images], true)
                end
                self.images = args.images
            end
            -- animation
            if not args.animations and args.animation then 
                args.animations = { args.animation }
            end 
            if args.animations then
                if type(args.animations) == 'table' then
                    for _, anim_name in ipairs(args.animations) do
                        if not args.animation then
                            args.animation = anim_name
                        end
                        self.animList[anim_name] = Image{file=args, animation=anim_name, skip_update=true}
                        self.animList[anim_name]._parent = self
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
            if args.auto_draw ~= false then self:addDrawable() end
            table.update(self, spawn_args or {})
            if self.spawn then
                if spawn_args then self:spawn(unpack(spawn_args))
                else self:spawn() end
            end
            if self.hasHitbox then
                Hitbox.teleport(self)
            end
            if self.body and self.body.is_physics then self.body:setPosition(self.x, self.y) end
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
            if not self._preset_size and obj then
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
        _draw = function(self,...)
            local extra_args = {...}
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
                        anim:draw()
                        if not self._preset_size then
                            self.width, self.height = anim.width, anim.height
                        end
                    end
                end
                if self._custom_draw then
                    self:_custom_draw(draw_fn, unpack(extra_args))
                else
                    draw_fn()
                end
                -- postdraw
                if self.postdraw then
                    self:postdraw()
                end
            end, 'function')
        end;
        draw = function(self,...) self:_draw(...) end;
        getDrawable = function(self)
            if self.image then 
                return self.imageList[self.image]:getDrawable()
            elseif self.animation then 
                return self.animList[self.animation]:getDrawable()
            end
        end;
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
                get = function()
                    return Game.get(name)
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
    local groups = {}
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

    local isPressed = function(name)
        if Input.group then 
            name = Input.group .. '.' .. name
        end 
        if not (table.hasValue(options.no_repeat, name) and pressed[name] and pressed[name].count > 1) and joycheck(pressed[name]) then
            return pressed[name]
        end
    end

    local isReleased = function(name)
        if Input.group then 
            name = Input.group .. '.' .. name
        end 
        if joycheck(released[name]) then
            return released[name]
        end
    end

    Input = callable {
        __call = function(self, name)
            return store[name] or pressed[name] or released[name]
        end;

        group = nil;

        store = function(name, value)
            store[name] = value
        end;

        set = function(inputs, _options)
            _options = _options or {}
            for name, inputs in pairs(inputs) do
                Input.setInput(name, inputs, _options.group)
            end
            
            if _options.combo then 
                table.append(options.combo, _options.combo or {})
            end 
            if _options.no_repeat then 
                table.append(options.no_repeat, _options.no_repeat or {})
            end
                
            return nil
        end;

        setInput = function(name, inputs, group)
            if group then name = group .. '.' .. name end
            local input_group_str = name
            name_to_input[name] = {}
            for _,i in ipairs(inputs) do name_to_input[name][i] = false end
            for _,i in ipairs(inputs) do
                if not input_to_name[i] then input_to_name[i] = {} end
                if not table.hasValue(input_to_name[i], name) then table.insert(input_to_name[i], name) end
            end
        end;

        pressed = function(...)
            local ret = {}
            local args = {...}
            local val
            for _, name in ipairs(args) do
                val = isPressed(name)
                if val then table.insert(ret, val) end
            end
            if #ret > 0 then return ret end
        end;

        released = function(...)
            local ret = {}
            local args = {...}
            local val
            for _, name in ipairs(args) do
                val = isReleased(name)
                if val then table.insert(ret, val) end
            end
            if #ret > 0 then return ret end
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
            store['wheel'] = nil
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
    local hex2rgb = function(hex)
        assert(type(hex) == "string", "hex2rgb: expected string, got "..type(hex).." ("..hex..")")
        hex = hex:gsub("#","")
        if(string.len(hex) == 3) then
        return {tonumber("0x"..hex:sub(1,1)) * 17 / 255, tonumber("0x"..hex:sub(2,2)) * 17 / 255, tonumber("0x"..hex:sub(3,3)) * 17 / 255}
        elseif(string.len(hex) == 6) then
            return {tonumber("0x"..hex:sub(1,2)) / 255, tonumber("0x"..hex:sub(3,4)) / 255, tonumber("0x"..hex:sub(5,6)) / 255}
        end
    end

    local fonts = {} -- { 'path+size': [ Font, Text ] }

    local getFont = function(path, size)
        size = size or 12
        local key = path..'+'..size
        if fonts[key] then return fonts[key] end

        local fnt = love.graphics.newFont(Game.res('font',path), size)
        local txt = love.graphics.newText(fnt)

        assert(fnt, 'Font not found: \''..path..'\'')

        local font = { fnt, txt }
        fonts[key] = font
        return font
    end

    local setText = function(text, limit, align)
        if not Draw.text then return false end
        if not text then text = "|" end
        if limit or align then
            Draw.text:setf(text or '', limit or Game.width, align or 'left')
        else
            Draw.text:set(text or '')
        end
        return true
    end

    local DEF_FONT = "04B_03.ttf"
    local last_font

    Draw = callable {
        crop_used = false;
        font = nil;
        text = nil;
        __call = function(self, instructions)
            for _,instr in ipairs(instructions) do
                name, args = instr[1], table.slice(instr,2)
                assert(Draw[name], "bad draw instruction '"..name.."'")
                local good, err = pcall(Draw[name], unpack(args))
                if not good then
                    error("Error: Draw."..name.."("..tbl_to_str(args)..")\n"..err, 3)
                end
            end
        end;
        setFont = function(path, size)
            path = path or last_font or DEF_FONT
            last_font = path
            local info = getFont(path, size)

            Draw.font = info[1]
            Draw.text = info[2]

            love.graphics.setFont(Draw.font)

        end;
        setFontSize = function(size)
            Draw.setFont(last_font, size)
        end;
        textWidth = function(...)
            if setText(...) then
                return Draw.text:getWidth()
            end
        end;
        textHeight = function(...)
            if setText(...) then
                return Draw.text:getHeight()
            end
        end;
        textSize = function(...)
            if setText(...) then
                return Draw.text:getDimensions()
            end
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
        print = function(txt,x,y,limit,align,r,...)
            if setText(txt,limit,align) then
                x = x or 0
                y = y or 0
                love.graphics.draw(Draw.text, x, y,r or 0,...)
            end
        end;
        parseColor = memoize(function(...)
            local r, g, b, a = ...
            if r == nil or r == true then
                -- no color given
                r, g, b, a = 1, 1, 1, 1
                return r, g, b, a
            end
            if type(r) == "table" then
                r, g, b, a = r[1], r[2], r[3], r[4]
            end
            local c = Color[r]
            if c then
                -- color string
                r, g, b, a = c[1], c[2], c[3], g
            elseif type(r) == "string" and r:starts("#") then 
                -- hex string
                r, g, b = unpack(hex2rgb(r))
            end 

            if not a then a = 1 end
            -- convert and clamp to [0,1]
            if r > 1 then r = clamp(floor(r) / 255, 0, 1) end
            if g > 1 then g = clamp(floor(g) / 255, 0, 1) end
            if b > 1 then b = clamp(floor(b) / 255, 0, 1) end
            if a > 1 then a = clamp(floor(a) / 255, 0, 1) end

            return r, g, b, a
        end);
        color = function(...)
            return love.graphics.setColor(Draw.parseColor(...))
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
            love.graphics.rotate(r)
        end;
        translate = function(x,y)
            love.graphics.translate(floor(x), floor(y))
        end;
        reset = function(only)
            local lg = love.graphics
            if only == 'color' or not only then
                lg.setColor(1,1,1,1)
                lg.setLineWidth(1)
            end
            if only == 'transform' or not only then
                lg.origin()
            end
            if (only == 'crop' or not only) and Draw.crop_used then
                Draw.crop_used = false
                lg.setScissor()
                -- lg.setStencilTest()
            end
        end;
        push = function() love.graphics.push('all') end;
        pop = function()
            Draw.reset('crop')
            love.graphics.pop()
        end;
        stack = function(fn)
            local lg = love.graphics
            lg.push('all')
            fn()
            lg.pop()
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
        'setLineWidth','setLineJoin','setPointSize',
        'applyTransform', 'replaceTransform'
    }
    local draw_aliases = {
        polygon = 'poly',
        rectangle = 'rect',
        setLineWidth = 'lineWidth',
        setLineJoin = 'lineJoin',
        setPointSize = 'pointSize',
        points = 'point',
        setFont = 'font',
        setFontSize = 'fontSize'
    }
    for _,fn in ipairs(draw_functions) do
        Draw[fn] = function(...)
            return love.graphics[fn](...)
        end
    end
    for old, new in pairs(draw_aliases) do
        Draw[new] = Draw[old]
    end
end
--COLOR
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
    black2 =     {33,33,33},
    transparent ={255,255,255,0}
}

--AUDIO
Audio = nil
Source = nil
do
    local default_opt = {
        type = 'static'
    }
    local defaults = {}
    local sources = {}
    local play_queue = {}
    local first_update = true

    local opt = function(name, overrides)
        if not defaults[name] then Audio(name, {}) end
        return defaults[name]
    end
    Source = class {
        init = function(self, name, options)
            self.name = name
            local o = opt(name)
            if options then o = table.update(o, options) end

            if Window.os == 'web' then o.type = 'static' end

            self.src = Cache.get('Audio.source',name,function(key)
                return love.audio.newSource(Game.res('audio',o.file), o.type)
            end):clone()

            if not sources[name] then sources[name] = {} end

            if o then
                table.insert(sources[name], self)
                local props = {'position','looping','volume','airAbsorption','pitch','relative','rolloff','effect','filter'}
                local t_props = {'attenuationDistances','cone','direction','velocity','volumeLimits'}
                for _,n in ipairs(props) do

                    local fn_name = n:capitalize()
                    -- setter
                    if not self['set'..fn_name] then
                        self['set'..fn_name] = function(self, ...)
                            return self.src['set'..fn_name](self.src, ...)
                        end
                    end
                    -- getter
                    if not self['get'..fn_name] then
                        self['get'..fn_name] = function(self, ...)
                            return self.src['get'..fn_name](self.src, ...)
                        end
                    end

                    if o[n] then self['set'..fn_name](self,o[n]) end
                end
                for _,n in ipairs(t_props) do

                    local fn_name = n:capitalize()
                    -- setter
                    if not self['set'..fn_name] then
                        self['set'..fn_name] = function(self, ...)
                            local args = {...}

                            if fn == "position" then
                                for i, v in ipairs(args) do
                                    args[i] = v / Audio.hearing
                                end
                            end

                            return self.src['set'..fn_name](self.src, unpack(args))
                        end
                    end
                    -- getter
                    if not self['get'..fn_name] then
                        self['get'..fn_name] = function(self, ...)
                            return self.src['get'..fn_name](self.src, ...)
                        end
                    end

                    if o[n] then self['set'..fn_name](self,unpack(o[n])) end
                end
            end
        end;
        setPosition = function(self, opt)
            self.position = opt or self.position
            if opt then
                self.src:setPosition(
                    (opt.x or 0) / Audio._hearing,
                    (opt.y or 0) / Audio._hearing,
                    (opt.z or 0) / Audio._hearing
                )
            end
        end;
        play = function(self)
            love.audio.play(self.src)
        end;
        stop = function(self)
            love.audio.stop(self.src)
        end;
        isPlaying = function(self)
            return self.src:isPlaying()
        end
    }
    Audio = callable {
        __call = function(self, file, ...)
            option_list = {...}
            for _,options in ipairs(option_list) do
                store_name = options.name or file
                options.file = file
                if not defaults[store_name] then defaults[store_name] = {} end
                new_tbl = copy(default_opt)
                table.update(new_tbl, options)
                table.update(defaults[store_name], new_tbl)

                Audio.source(store_name)
            end
        end;

        _hearing = 6;

        hearing = function(h)
            Audio._hearing = h or Audio._hearing
            for name, src_list in pairs(sources) do
                for _, src in ipairs(src_list) do
                    src:setPosition()
                end
            end
        end;

        update = function(dt)
            if #play_queue > 0 then
                for _, src in ipairs(play_queue) do
                    src:play()
                end
                play_queue = {}
            end
        end;

        source = function(name, options)
            return Source(name, options)
        end;

        play = function(name, options)
            local new_src = Audio.source(name, options)
            table.insert(play_queue, new_src)
            return new_src
        end;
        stop = function(...)
            names = {...}
            if #names == 0 then love.audio.stop()
            else
                for _,n in ipairs(names) do
                    if sources[n] then
                        for _,src in ipairs(sources[n]) do src:stop() end
                    end
                end
            end
        end;
        isPlaying = function(name)
            if sources[name] then
                local t = {}
                for _,src in ipairs(sources[name]) do
                    if src:isPlaying() then return true end
                end
            end
            return false
        end;
    }

    local audio_fns = {'volume','velocity','position','orientation','effect','dopplerScale'}
    for _, fn in ipairs(audio_fns) do
        local fn_capital = fn:capitalize()
        Audio[fn] = function(...)
            local args = {...}

            if fn == "position" then
                local pos = args[1]

                args = {
                    (pos.x or 0) / Audio._hearing,
                    (pos.y or 0) / Audio._hearing,
                    (pos.z or 0) / Audio._hearing
                }
            end

            if #args > 0 then
                love.audio['set'..fn_capital](unpack(args))

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
            shader = shader,
            auto_vars = info.opt.auto_vars
        }
    end

    Effect = GameObject:extend {
        library = function() return library end;
        new = function(name, in_opt)
            local opt = { use_canvas=true, vars={}, unused_vars={}, integers={}, code=nil, effect='', vertex='', auto_vars=false }
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
                self.auto_vars = {}
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
                self.auto_vars[name] = self.shader_info[name].auto_vars
                table.update(self.vars[name], self.shader_info[name].vars)
            end
        end;
        disable = function(self, ...)
            if not Feature('effect') then return end
            local disable_names = {...}
            for _,name in ipairs(disable_names) do
                self.disabled[name] = true
            end
            local new_names = {}
            self.used = false
            for _,name in ipairs(self.names) do
                tryEffect(name)
                if not self.disabled[name] then
                    self.used = true
                    table.insert(new_names, name)
                end
            end
            self:updateShader(new_names)
        end;
        enable = function(self, ...)
            if not Feature('effect') then return end
            local enable_names = {...}
            for _,name in ipairs(enable_names) do
                self.disabled[name] = false
            end
            local new_names = {}
            self.used = false
            for _,name in ipairs(self.names) do
                tryEffect(name)
                if not self.disabled[name] then
                    self.used = true
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

            for _,name in ipairs(self.names) do
                if not self.disabled[name] then
                    vars = self.vars[name]
                    vars.time = vars.time + dt
                    vars.tex_size = {Game.width,Game.height}

                    if self.auto_vars[name] then
                        vars.inputSize = {Game.width,Game.height}
                        vars.outputSize = {Game.width,Game.height}
                        vars.textureSize = {Game.width,Game.height}
                    end
                    -- send all the vars
                    for k,v in pairs(vars) do
                        self:send(name, k, v)
                    end

                    if library[name] and library[name].opt.update then
                        library[name].opt.update(self.vars[name])
                    end
                end
            end
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
                if not self.disabled[name] then
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
    local default_opt = { x=0, y=0, offset_x=0, offset_y=0, view_x=0, view_y=0, z=0, dx=0, dy=0, angle=0, zoom=nil, scalex=1, scaley=nil, top=0, left=0, width=nil, height=nil, follow=nil, enabled=true, auto_use=true }
    local attach_count = 0
    local options = {}
    local cam_stack = {}

    Camera = callable {
        transform = nil;
        __call = function(self, name, opt)
            opt = opt or {}
            default_opt.width = Game.width
            default_opt.height = Game.height
            options[name] = copy(default_opt)
            options[name].transform = love.math.newTransform()
            options[name].name = name
            table.update(options[name], opt)
            sort(options, 'z', 0)
            return options[name]
        end;
        get = function(name) return assert(options[name], "Camera :'"..name.."' not found") end;
        attach = function(name)
            local o = Camera.get(name)
            Draw.push()
            if o.enabled == false then return end
            if o then
                local w, h = o.width or Game.width, o.height or Game.height
                if o.follow then
                    o.x = o.follow.x or o.x
                    o.y = o.follow.y or o.y
                end
                local half_w, half_h = floor(w/2), floor(h/2)

                if o.crop then Draw.crop(o.view_x, o.view_y, w, h) end
                o.transform:reset()
                o.transform:translate(half_w + o.view_x, half_h + o.view_y)
                o.transform:scale(o.zoom or o.scalex, o.zoom or o.scaley or o.scalex)
                o.transform:rotate(o.angle)
                o.transform:translate(-floor(o.x - o.left + o.dx), -floor(o.y - o.top + o.dy))

                o.offset_x = -(floor(half_w) -floor(o.x - o.left + o.dx))
                o.offset_y = -(floor(half_h) -floor(o.y - o.top + o.dy))

                Camera.transform = o.transform
                love.graphics.replaceTransform(o.transform)

                table.insert(cam_stack, name)
            end
        end;
        coords = function(name, x, y)
            local o = Camera.get(name)
            if o then
                return x + (o.offset_x or 0), y + (o.offset_y or 0)
            end
            return x, y
        end;
        detach = function()
            Draw.pop()
            Camera.transform = nil
            table.remove(cam_stack)
        end;
        use = function(name, fn)
            Camera.attach(name)
            fn()
            Camera.detach()
        end;
        count = function() return table.len(options) end;
        useAll = function(fn)
            for name, opt in pairs(options) do
                if opt.auto_use then
                    Camera.use(name, fn)
                else
                    fn()
                end
            end
        end;
    }
end

--SPRITEBATCH
SpriteBatch = nil
do
    local batches = {}

    _SB = GameObject:extend {
        init = function(self, img_path, z, skip_store)
            GameObject.init(self, {classname='SpriteBatch'})
            self.z = z or 0
            local key = img_path..tostring(self.z)
            
            -- get image
            self.img = getImage(img_path)
            
            -- get spritebatch
            self.sb = Cache.get('spritebatch', img_path..':'..self.z, function(key)
                return love.graphics.newSpriteBatch(self.img)
            end)

            self.img_path = img_path
            if not skip_store then 
                batches[key] = self
            end
            self:addDrawable()
        end;
        set = function(self, in_quad, in_transform, id)
            in_quad = in_quad or { 0, 0, 1, 1 }
            in_transform = in_transform or { 0, 0 }
                
            -- get quad
            local tx, ty, tw, th = unpack(in_quad)
            local quad = Cache.get('spritebatch.quad', self.img_path..':'..tx..","..ty..","..tw..","..th, function(key)
                return love.graphics.newQuad(tx,ty,tw,th,self.img:getWidth(),self.img:getHeight())
            end)
            if id then 
                self.sb:set(id, quad, unpack(in_transform))
                return id
            else 
                return self.sb:add(quad, unpack(in_transform))
            end
        end;
        remove = function(self, id)
            return self.sb:set(id, 0, 0, 0, 0, 0)
        end;
        _draw = function(self)
            Game.drawObject(self, self.sb)
        end;
        draw = function(self) self:_draw() end;
    }

    SpriteBatch = callable {
        __call = function(self, file, z, skip_store)
            local key = file..tostring(z or 0)
            if not skip_store and batches[key] then 
                return batches[key] or _SB(file, z, skip_store)
            end 
            return _SB(file, z, skip_store)
        end;
        set = function(in_image, in_quad, in_transform, in_z, id)
            in_quad = in_quad or { 0, 0, 1, 1 }
            in_transform = in_transform or { 0, 0 } 
            in_z = in_z or 0 
            local key = in_image..tostring(in_z or 0)

            local sb = SpriteBatch(in_image, in_z)
            return sb:set(in_quad, in_transform, id)
        end;
        remove = function(self, id, in_image, in_z)
            in_z = in_z or 0 
            local key = in_image..tostring(in_z or 0)

            local sb = batches[key]
            if sb then
                return sb:remove(id)
            end
        end;
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
        load = function(name, opt)
            local data = love.filesystem.read(Game.res('map',name))
            assert(data,"Error loading map '"..name.."'")
            local new_map = Map(opt)
            data = json.decode(data)
            new_map.data = data
            local layer_name = {}
            -- get layer names
            local store_layer_order = false

            if #new_map.layer_order == 0 then
                new_map.layer_order = {}
                store_layer_order = true
            end
            for i = #data.layers, 1, -1 do
                local info = data.layers[i]
                layer_name[info.uuid] = info.name
                if store_layer_order then
                    table.insert(new_map.layer_order, info.name)
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
            -- make paths
            for obj_uuid, info in pairs(data.paths) do
                local obj_info = getObjInfo(obj_uuid)
                local obj_name = obj_info.name
                for layer_uuid, info in pairs(info) do
                    local layer_name = layer_name[layer_uuid]
                    local new_path = Path()
                    -- add nodes
                    local tag
                    for node_key, info in pairs(info.node) do
                        if type(info[3]) == "string" then tag = info[3] else tag = nil end
                        new_path:addNode{x=info[1], y=info[2], tag=tag}
                    end
                    -- add edges
                    for node1, edge_info in pairs(info.graph) do
                        for node2, tag in pairs(edge_info) do
                            local _, node1_hash = new_path:getNode{x=info.node[node1][1], y=info.node[node1][2], tag=info.node[node1][3]}
                            local _, node2_hash = new_path:getNode{x=info.node[node2][1], y=info.node[node2][2], tag=info.node[node2][3]}
                            if type(tag) ~= "string" then tag = nil end
                            new_path:addEdge{a=node1_hash, b=node2_hash, tag=tag}
                        end
                    end

                    if not new_map.paths[obj_name] then
                        new_map.paths[obj_name] = {}
                    end
                    if not new_map.paths[obj_name][layer_name] then
                        new_map.paths[obj_name][layer_name] = {}
                    end
                    -- get color
                    if obj_info then
                        new_path.color = { Draw.parseColor(obj_info.color) }
                    end
                    table.insert(new_map.paths[obj_name][layer_name], new_path)
                end
            end

            -- spawn entities/hitboxes
            for obj_uuid, info in pairs(data.objects) do
                local obj_info = getObjInfo(obj_uuid)
                if obj_info then
                    for l_uuid, coord_list in pairs(info) do
                        for _,c in ipairs(coord_list) do
                            local hb_color = { Draw.parseColor(obj_info.color) }
                            hb_color[4] = 0.3
                            -- spawn entity
                            if Game.isSpawnable(obj_info.name) then
                                local obj = new_map:_spawnEntity(obj_info.name,{
                                    map_tag=c[1], x=c[2], y=c[3], z=new_map:getLayerZ(layer_name[l_uuid]), layer=layer_name[l_uuid], points=copy(c),
                                    map_width=obj_info.size[1], map_height=obj_info.size[2], hitboxColor=hb_color
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

            new_map:addDrawable()
            return new_map
        end;
        config = function(opt)
            if opt then options = opt end
            return options
        end;
        init = function(self, opt)
            self.batches = {} -- { layer: SpriteBatch }
            self.hb_list = {}
            self.entity_info = {} -- { obj_name: { info_list... } }
            self.entities = {} -- { layer: { entities... } }
            self.paths = {} -- { obj_name: { layer_name:{ Paths... } } }
            self.layer_order = {}
            GameObject.init(self, {classname="Map"}, spawn_args)
        end;
        addDrawable = function(self)
            for layer, batches in pairs(self.batches) do
                for _, batch in pairs(batches) do
                    batch:addDrawable()
                end
            end
            for layer, entities in pairs(self.entities) do
                for _, entity in ipairs(entities) do
                    entity:addDrawable()
                end
            end
        end;
        remDrawable = function(self)
            for layer, batches in pairs(self.batches) do
                for _, batch in pairs(batches) do
                    batch:remDrawable()
                end
            end
            for layer, entities in pairs(self.entities) do
                for _, entity in ipairs(entities) do
                    entity:remDrawable()
                end
            end
        end;
        _draw = function(self)
            Game.drawObject(self, function()
                local layer
                for i = 1, #self.layer_order do
                    layer = self.layer_order[i]
                    local batches = self.batches[layer]
                    if batches then
                        for _, batch in pairs(batches) do
                            batch:draw()
                        end
                    end
                    local entities = self.entities[layer]
                    local reorder = iterateEntities(entities, 'z', function(entity)
                        entity:draw()
                    end)
                    if reorder then
                        --sort(entities, 'z', 0)
                    end
                end
            end, true)
        end;
        _destroy = function(self)
            -- destroy hitboxes
            for _,tile in ipairs(self.hb_list) do
                Hitbox.remove(tile)
            end
            self.hb_list = {}
            -- destroy entities
            for layer, entities in pairs(self.entities) do
                for _,ent in ipairs(entities) do
                    ent:destroy()
                end
            end
            self.entities = {}
            -- destroy spritebatches
            for layer, batches in ipairs(self.batches) do 
                for _,batch in pairs(batches) do
                    batch:destroy()
                end
            end
            self.batches = {}
        end;
        draw = function(self) self:_draw() end,
        addTile = function(self,file,x,y,tx,ty,tw,th,layer)
            layer = layer or '_'
            local tile_info = { x=x, y=y, width=tw, height=th, tag=hb_name, quad={ tx, ty, tw, th }, transform={ x, y } }

            -- add tile to spritebatch
            -- print('need',file,unpack(tile_info.quad))
            if not self.batches[layer] then 
                self.batches[layer] = {}
            end
            local sb = self.batches[layer][file]
            if not sb then sb = SpriteBatch(file, self:getLayerZ(layer), true) end
            self.batches[layer][file] = sb
            local id = sb:set(tile_info.quad, tile_info.transform)
            tile_info.id = id

            -- hitbox
            local hb_name = nil
            if options.tile_hitbox then hb_name = options.tile_hitbox[FS.removeExt(FS.basename(file))] end
            local body = nil
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
        getPaths = function(self, obj_name, layer_name)
            local ret = {}
            if self.paths[obj_name] then
                if layer_name and self.paths[obj_name][layer_name] then
                    return self.paths[obj_name][layer_name]
                else
                    for layer_name, paths in pairs(self.paths[obj_name]) do
                        for _, path in ipairs(paths) do
                            table.insert(ret, path)
                        end
                    end
                end
            end
            return ret
        end;
        _spawnEntity = function(self, ent_name, opt)
            local obj = Game.spawn(ent_name, opt)
            if obj then
                opt.layer = opt.layer or "_"
                return self:addEntity(obj, opt.layer)
            end
        end;
        spawnEntity = function(self, ent_name, x, y, layer)
            layer = layer or "_"
            obj_info = getObjInfo(ent_name, true)
            if obj_info then
                obj_info.x = x
                obj_info.y = y
                obj_info.z = self:getLayerZ(layer)
                obj_info.layer = layer or "_"
                return self:_spawnEntity(ent_name, obj_info)
            end
        end;
        addEntity = function(self, obj, layer_name)
            layer_name = layer_name or "_"
            if not self.entities[layer_name] then self.entities[layer_name] = {} end
            table.insert(self.entities[layer_name], obj)
            obj:remDrawable()
            sort(self.entities[layer_name], 'z', 0)
            return obj
        end;
        add = function(self, ...)
            local args = {...}

            local obj = args[1]
            if obj.is_entity then
                return self:addEntity(unpack(args))
            end
            if not obj.is_entity and obj.hasHitbox then 
                table.insert(self.hb_list, new_hb)
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
            for i, name in ipairs(self.layer_order) do
                if name == l_name then return i end
            end
            return 0
        end;
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
        init = function(self)
            self.is_physics = true
        end;
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

    local queryFilter = function(item)
        return not tag or item.tag == tag
    end
    local calcBounds = function(obj)
        local repos = false
        if obj.is_entity then
            repos = obj:_checkForAnimHitbox()
        else
            obj.align = 'center'
            obj.scale = obj.scale or 1
            obj.scalex = obj.scalex or 1
            obj.scaley = obj.scaley or 1
        end
        obj.width = max(obj.width, 1) 
        obj.height = max(obj.height, 1)     
        return  obj.alignx,
                obj.aligny,
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

        hb.left = hb.left or 0
        hb.top = hb.top or 0
        hb.right = hb.right or 0
        hb.bottom = hb.bottom or 0

        if not obj.hasHitbox then
            obj.hasHitbox = true
            new_boxes = true

            world:add(
                obj, obj.x - hb.left, obj.y - hb.top,
                abs(obj.width) + hb.right, abs(obj.height ) + hb.bottom
            )
        end

        obj.hitbox = hb

        if repos then
            Hitbox.teleport(obj)
        end
        return obj.hitbox, hb.left + left, hb.top + top
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
                local hb, offx, offy = checkHitArea(obj)
                world:update(obj,
                    obj.x - offx, obj.y - offy,
                    abs(obj.width ) + hb.right, abs(obj.height ) + hb.bottom
                )
            end
        end;
        at = function(x, y, tag)
            return world:queryPoint(x, y, queryFilter)
        end;
        within = function(x, y, w, h, tag)
            return world:queryRect(x, y, queryFilter)
        end;
        sight = function(x1, y1, x2, y2, tag)
            return world:querySegment(x1, y1, x2, y2, queryFilter)
        end;
        move = function(obj)
            if obj and not obj.destroyed and obj.hasHitbox then
                local filter_result
                local filter = function(_obj, other)
                    local ret = _obj.reaction or Hitbox.default_reaction
                    if _obj.reactions and _obj.reactions[other.tag] then ret = _obj.reactions[other.tag] else
                        if _obj.reaction then ret = _obj.reaction end
                    end
                    if other.reactions and other.reactions[_obj.tag] then ret = other.reactions[_obj.tag] else
                        if other.reaction then ret = other.reaction end
                    end
                    if _obj.filter then ret = _obj:filter(other) end

                    filter_result = ret

                    if ret == 'static' then 
                        ret = 'slide'
                    end 
                    return ret
                end
                -- move the hitbox
                local hb, offx, offy = checkHitArea(obj)

                local new_x, new_y, cols, len = world:move(obj,
                    obj.x - offx,
                    obj.y - offy,
                    filter)
                if obj.destroyed then return end
                if filter_result ~= 'static' then
                    obj.x = new_x + offx
                    obj.y = new_y + offy
                end

                local swap = function(t, key1, key2)
                    local temp = t[key1]
                    t[key1] = t[key2]
                    t[key2] = temp
                end
                if len > 0 then
                    local hspeed, vspeed, bounciness, nx, ny
                    for i=1,len do
                        hspeed, vspeed, bounciness = obj.hspeed, obj.vspeed, obj.bounciness or 1
                        nx, ny = cols[i].normal.x, cols[i].normal.y
                        
                        -- change velocity by collision normal
                        if cols[i].bounce then
                            print(bounciness, nx, ny)
                            if hspeed and ((nx < 0 and hspeed > 0) or (nx > 0 and hspeed < 0)) then 
                                obj.hspeed = -obj.hspeed * bounciness
                            end
                            if vspeed and ((ny < 0 and vspeed > 0) or (ny > 0 and vspeed < 0)) then 
                                obj.vspeed = -obj.vspeed * bounciness
                            end
                        end
                        
                        if not obj or obj.destroyed then return end
                        if obj.collision then obj:collision(cols[i]) end 

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
                local x,y,w,h
                if new_boxes then
                    new_boxes = false
                    hb_items, hb_len = world:getItems()
                end
                for _,i in ipairs(hb_items) do
                    if i.hasHitbox and not i.destroyed then
                        x,y,w,h = world:getRect(i)
                        Draw.color(i.hitboxColor or {1,0,0,0.9})
                        Draw.rect('line',x,y,w,h)
                        Draw.color(i.hitboxColor or {1,0,0,0.25})
                        Draw.rect('fill',x,y,w,h)
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
            Timer.stop(name)
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
            if not Net.connected or not obj or not (obj.net or obj.net_obj) then return end
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
            setMode(w,h,flags)
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
                if not Window.fullscreen() then
                    pre_fs_size = {Game.width, Game.height}
                end
                res = love.window.setFullscreen(v,fs_type)
            end
            Game.updateWinSize(unpack(pre_fs_size))
            return res
        end;
        toggleFullscreen = function()
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
    local clamp = Math.clamp

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
            state_created = State.curr_state,
            destroy = function()
                tbl[id] = nil
            end
        }
        tbl[id] = timer
        return timer
    end

    Timer = {
        update = function(dt, dt_ms)
            -- after
            for id,timer in pairs(l_after) do
                if not timer.paused then
                    timer.t = timer.t - dt_ms
                    timer.p = clamp((timer.duration - timer.t) / timer.duration, 0, 1)
                    if timer.t < 0 then
                        local new_t = timer.fn and timer.fn(timer)
                        if new_t then
                            -- another one (restart timer)
                            timer.duration = (type(new_t) == "number" and new_t or timer.duration)
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
                    timer.t = timer.t - dt_ms
                    timer.p = clamp((timer.duration - timer.t) / timer.duration, 0, 1)
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
            assert(t, "Timer duration is nil")
            return addTimer(t, fn, l_after)
        end,
        every = function(t, fn)
            assert(t, "Timer duration is nil")
            return addTimer(t, fn, l_every)
        end,
        stop = function(state_name)
            for _, tmr in pairs(l_after) do
                if not state_name or tmr.state_created == state_name then
                    tmr.destroy()
                end
            end
            for _, tmr in pairs(l_every) do
                if not state_name or tmr.state_created == state_name then
                    tmr.destroy()
                end
            end
        end
    }
end

--PATH
Path = {}
do
    local lerp, distance, sign = Math.lerp, Math.distance, Math.sign
    local hash_node = function(x,y,tag)
        local parts = {}
        if tag then parts = {tag} end
        if not tag then parts = {x,y} end
        return table.join(parts,',')
    end

    local hash_edge = function(node1,node2)
        return table.join({node1,node2},':'), table.join({node2,node1},':')
    end

    Path = GameObject:extend {
        debug = false;
        -- TODO: Disjkstra cache (clear when node/edge changes)
        init = function(self)
            GameObject.init(self, {classname="Path"})

            self.color = 'blue'
            self.node = {} -- { hash:{x,y,tag} }
            self.edge = {} -- { hash:{node1:hash, node2:hash, direction:-1,0,1, tag} }
            self.matrix = {} -- adjacency matrix containg node/edge info

            self.pathing_objs = {} -- { obj... }

            self:addUpdatable()
            self:addDrawable()
        end;
        addNode = function(self, opt)
            if not opt then return end
            local hash = hash_node(opt.x, opt.y, opt.tag)

            self.node[hash] = copy(opt)
            -- setup edges in matrix
            self.matrix[hash] = {}
            for xnode, edges in pairs(self.matrix) do
                if xnode ~= hash and not edges[hash] then edges[hash] = nil end
            end

            return hash
        end;
        getNode = function(self, opt)
            opt = opt or {}
            local hash = hash_node(opt.x, opt.y, opt.tag)
            assert(self.node[hash], "Node '"..hash.."' not in path")
            return self.node[hash], hash
        end;
        addEdge = function(self, opt)
            opt = opt or {}
            local hash = hash_edge(opt.a, opt.b)

            assert(self.node[opt.a], "Node '"..(opt.a or 'nil').."' not in path")
            assert(self.node[opt.b], "Node '"..(opt.b or 'nil').."' not in path")

            local node1, node2 = self.node[opt.a], self.node[opt.b]
            opt.length = floor(Math.distance(node1.x, node1.y, node2.x, node2.y))

            self.edge[hash] = copy(opt)
            -- add edge to matrix
            for xnode, edges in pairs(self.matrix) do
                if not edges[hash] then edges[hash] = nil end
            end
            self.matrix[opt.a][opt.b] = hash

            return hash
        end;
        getEdge = function(self, opt)
            opt = opt or {}
            local hash1, hash2 = hash_edge(opt.a, opt.b)
            assert(self.edge[hash1] or self.edge[hash2], "Edge '"..hash1.."'/'"..hash2.."' not in path")
            return self.edge[hash1] or self.edge[hash2], hash
        end;
        go = function(self, obj, opt)
            opt = opt or {}
            local speed = opt.speed or 1
            local target = opt.target
            local start = opt.start

            assert(target, "Path:go() requires target node")

            if obj.is_pathing and opt.force then
                self:stop(obj)
            end

            if not obj.is_pathing then
                local extra_dist = 0
                obj.is_pathing = { uuid=uuid(), direction={x=1, y=1}, speed=speed, index=1, path={}, t=0, prev_pos={obj.x,obj.y}, onFinish=opt.onFinish }
                table.insert(self.pathing_objs, obj)
                
                if not start then
                    -- find nearest node
                    local closest_node
                    local d = -1
                    local new_d
                    for hash, info in pairs(self.node) do
                        new_d = Math.distance(info.x,info.y,obj.x,obj.y)
                        if new_d < d or d < 0 then
                            d = new_d
                            closest_node = info
                        end
                    end
                    if closest_node then
                        extra_dist = new_d
                        start = closest_node
                    end
                end

                -- perform Dijskstra to find shortest path
                local INF = math.huge
                local dist = {}
                local previous = {}
                local Q = {}
                local checked = {}
                local start_hash = hash_node(start.x, start.y, start.tag)
                local target_hash = hash_node(target.x, target.y, target.tag)

                for v, info in pairs(self.node) do
                    if v ~= target_hash then
                        dist[v] = INF
                    end
                    table.insert(Q, v)
                end
                dist[target_hash] = 0
                while #Q > 0 do
                     -- sort backwards to avoid using the slow table.remove(Q, 1)
                    table.sort(Q, function(a, b)
                        return dist[a] > dist[b]
                    end)
                    -- lowest distance
                    local u = Q[#Q]
                    table.remove(Q)

                    if dist[u] == INF then break end

                    -- iterate neighbors
                    for v, edge_hash in pairs(self.matrix[u]) do
                        if not checked[u] then
                            local alt = dist[u] + self.edge[edge_hash].length

                            if alt < dist[v] then
                                dist[v] = alt
                                previous[v] = u
                            end
                        end
                    end

                    checked[u] = true
                end

                local next_node = start_hash
                obj.is_pathing.total_distance = dist[start_hash] + extra_dist

                repeat
                    table.insert(obj.is_pathing.path, next_node)
                    next_node = previous[next_node]
                until not next_node
                
                table.insert(self.pathing_objs, obj)
            end
        end;
        -- static
        stop = function(self, obj)
            if obj.is_pathing then
                local next_node = self.node[obj.is_pathing.path[obj.is_pathing.index]]
                local onFinish = obj.is_pathing.onFinish
                table.filter(self.pathing_objs, function(_obj)
                    return obj.is_pathing.uuid ~= _obj.is_pathing.uuid
                end)
                obj.is_pathing = nil
                return next_node, onFinish
            end
        end;
        -- static
        pause = function(obj)
            if obj.is_pathing then
                obj.is_pathing.paused = true
            end
        end;
        -- static
        resume = function(obj)
            if obj.is_pathing then
                obj.is_pathing.paused = false
            end
        end;
        _update = function(self, dt)
            for _, obj in ipairs(self.pathing_objs) do
                local info = obj.is_pathing
                if info and not info.paused then
                    local next_node = self.node[info.path[info.index]]
                    local total_dist = info.total_distance
                    if not info.next_dist then
                        info.next_dist = distance(info.prev_pos[1],info.prev_pos[2],next_node.x,next_node.y)
                    end
                    info.t = info.t + ( info.speed / (info.next_dist / total_dist) ) * dt

                    if info.t >= 100 then
                        info.index = info.index + 1
                        info.t = 0
                        info.prev_pos = {obj.x, obj.y}
                        info.next_dist = nil
                    else 

                        obj.x = lerp(info.prev_pos[1], next_node.x, info.t / 100)
                        obj.y = lerp(info.prev_pos[2], next_node.y, info.t / 100)
    
                        -- store direction object is moving
                        local xdiff = floor(next_node.x - info.prev_pos[1])
                        local xsign = sign(xdiff)
                        if xdiff ~= 0 then info.direction.x = xsign end
    
                        local ydiff = floor(next_node.y - info.prev_pos[2])
                        local ysign = sign(ydiff)
                        if ydiff ~= 0 then info.direction.y = ysign end
    
                    end 
                    if info.index > #info.path then
                        local _, onFinish = self:stop(obj)
                        if onFinish then onFinish(obj) end
                    end
                end
            end
        end;
        _draw = function(self)
            if not (Path.debug or self.debug) then return end
            -- draw nodes
            for hash, node in pairs(self.node) do
                Draw{
                    {'color',self.color},
                    {'circle','fill',node.x,node.y,4},
                    {'color'}
                }
                local tag = node.tag or (node.x..','..node.y)
                if tag then
                    local tag_w = Draw.textWidth(tag)
                    local tag_h = Draw.textHeight(tag)
                    Draw{
                        {'color','black',0.8},
                        {'rect','fill',node.x,node.y,tag_w+2,tag_h+2,2},
                        {'color','white'},
                        {'print',tag,node.x+1,node.y+1},
                        {'color'}
                    }
                end
            end
            -- draw edges
            local node1, node2
            for hash, edge in pairs(self.edge) do
                node1 = self.node[edge.a]
                node2 = self.node[edge.b]
                Draw{
                    {'color',self.color},
                    {'line',node1.x,node1.y,node2.x,node2.y},
                    {'color'}
                }
                local tag = edge.tag
                if tag then
                    local tag_w = Draw.textWidth(tag)
                    local tag_h = Draw.textHeight(tag)
                    Draw{
                        {'color','gray',0.9},
                        {'rect','fill',(node1.x+node2.x)/2,(node1.y+node2.y)/2,tag_w+2,tag_h+2,2},
                        {'color','white'},
                        {'print',tag,(node1.x+node2.x)/2+1,(node1.y+node2.y)/2+1},
                        {'color'}
                    }
                end
            end
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

--Time
Time = {}
do
    local flr = Math.floor
    Time = {
        format = function(str, ms)
            local s = flr(ms / 1000) % 60
            local m = flr(ms / (1000 * 60)) % 60
            local h = flr(ms / (1000 * 60 * 60)) % 24
            local d = flr(ms / (1000 * 60 * 60 * 24))

            return str
                :replace("%%d", (d))
                :replace("%%h", (h))
                :replace("%%m", (m))
                :replace("%%s", (s))
        end,
        ms = function(opt)
            local o = function(k)
                if not opt then return 0
                else return opt[k] or 0 end
            end

            return o('ms') + (o('sec') * 1000) + (o('min') * 60000) + (o('hr') * 3600000) + (o('day') * 86400000)
        end
    }
end

--Timeline
Timeline = GameObject:extend {
    init = function(self, events, opt)
        GameObject.init(self, {classname="Timeline"}, opt)

		self.t = 0
		self.events = events
		self.index = 0
		self.running = false

		self:addUpdatable()
        self:addDrawable()
	end,
    pause = function(self)
        self.running = false
    end,
    resume = function(self)
        self.running = true
    end,
    play = function(self, name)
        self:step(name or 1)
        self.running = true
    end,
	step = function(self, name)
        self.t = 0
        self.waiting = false
		if type(name) == "string" then
			for i, ev in ipairs(self.events) do
				if ev.name == name then
					self.index = i
				end
			end

		elseif type(name) == "number" then
            while name < 0 do name = #self.events - name end
            self.index = name

        else
			self.index = self.index + 1
			-- stop the timeline and destroy it??
			if self.index > #self.events then
				self.running = false
				self:destroy()
			end

		end
        self:call()
	end,
	call = function(self, name, ...)
		local ev = self.events[self.index]
		if not ev then return end

        if not name then name = 'fn' end

		if name and ev[name] then
			-- call named fn
			ev[name](self, ...)
		end
	end,
    reset = function(self)
        self:step(1)
    end,
    _update = function(self, dt)
        if not self.running then return end

		self:call('update', dt)

		local ev = self.events[self.index]
		-- move onto next step?
		if not ev or #ev == 0 or (type(ev[1]) == "number" and self.t > ev[1]) then
			self:step()
        elseif ev and ev[1] == 'wait' and not self.waiting then
            self.waiting = true
        end

		self.t = self.t + dt * 1000
    end,
	_draw = function(self)
		self:call('draw')
	end,
    draw = function(self)
        self:_draw()
    end
}

--BACKGROUND
Background = nil
BFGround = nil
do
    local bg_list = {}
    local fg_list = {}

    local quad
    local add = function(opt)
        opt = opt or {}
        if opt.file then
            opt.image = Cache.get('Image', Game.res('image',opt.file), function(key)
                return love.graphics.newImage(key)
            end)
            opt.x = 0
            opt.y = 0
            opt.scale = 1
            opt.width = opt.image:getWidth()
            opt.height = opt.image:getHeight()
            if not quad then 
                quad = love.graphics.newQuad(0,0,1,1,1,1)
            end 
        end
        return opt
    end

    local update = function(list, dt)
        iterate(list, function(t)
            if t.remove == true then
                return true
            end

            if t.size == "cover" then
                if t.width < t.height then
                    t.scale = Game.width / t.width
                else
                    t.scale = Game.height / t.height
                end
                t.image:setWrap('clamp','clamp')
                t.x = (Game.width - (t.width * t.scale))/2
                t.y = (Game.height - (t.height * t.scale))/2
            else 
                t.image:setWrap('repeat','repeat')
            end 
        end)
    end

    local draw = function(list)
        local lg_draw = love.graphics.draw
        for _, t in ipairs(list) do
            if t.image then
                if t.size == 'cover' then 
                    lg_draw(t.image,0,0,0,t.scale,t.scale)
                else
                    quad:setViewport(-t.x,-t.y,Game.width,Game.height,t.width,t.height)
                    lg_draw(t.image,quad,0,0,0,t.scale,t.scale)
                end
            end
        end
    end

    BFGround = {
        update = function(dt)
            update(bg_list, dt)
            update(fg_list, dt)
        end;
    }

    Background = callable {
        __call = function(self, opt)
            local t = add(opt)
            table.insert(bg_list, opt)
            return t
        end;
        draw = function()
            draw(bg_list)
        end
    }
    Foreground = callable {
        __call = function(self, opt)
            local t = add(opt)
            table.insert(fg_list, opt)
            return t
        end;
        draw = function()
            draw(fg_list)
        end
    }
end

--PARTICLES
Particles = nil 
do 
    local methods = {
        rate = 'EmissionRate',
        area = 'EmissionArea',
        color = 'Colors',
        max = 'BufferSize',
        lifetime = 'ParticleLifetime',
        linear_accel = 'LinearAcceleration',
        linear_damp = 'LinearDamping',
        rad_accel = 'RadialAcceleration',
        relative = 'RelativeRotation',
        direction = 'Direction',
        rotation = 'Rotation',
        size_vary = 'SizeVariation',
        sizes = 'Sizes',
        speed = 'Speed',
        spin = 'Spin',
        spin_vary = 'SpinVariation',
        spread = 'Spread',
        tan_accel = 'TangentialAcceleration',
        position = 'Position',
        insert = 'InsertMode'
    }

    Particles = GameObject:extend {
        init = function(self, args)
            if type(args) == "string" then 
                args = { source = args }
            end 
            assert(args and args.source, "Particles instance needs 'src'")

            self._source = nil
            self.texture = nil
            self.quads = {}

            local frame = args.frame or 0
            local source = args.source
            args.frame = nil
            args.source = nil

            self:source(source)
            self._frame = frame -- entity-only setting

            -- initial psystem settings
            if self.psystem then 
                for k, v in pairs(args) do 
                    if methods[k] then
                        if type(v) == 'table' then 
                            self.psystem['set'..methods[k]](self.psystem, unpack(v)) 
                        else
                            self.psystem['set'..methods[k]](self.psystem, v) 
                        end
                    elseif self[k] and type(self[k]) == 'function' then  
                        if type(v) == 'table' then 
                            self[k](self, unpack(v)) 
                        else
                            self[k](self, v) 
                        end
                    end
                    args[k] = nil
                end
            end
            GameObject.init(self, {classname="Particles"}, args)

            -- getters/setters
            for k,v in pairs(methods) do 
                self[k] = function(self, ...) 
                    if self.psystem then 
                        self.psystem['set'..v](self.psystem, ...) 
                        return self.psystem['get'..v](self.psystem)
                    end
                end
            end

            self:addUpdatable()
            self:addDrawable()
        end,
        stop = function(self)
            self:rate(0)
        end,
        emit = function(self, n, args)
            args = args or {}
            table.update(args, self, {
                'x','y','angle','scalex','scaley',
                'offx','offy','shearx','sheary'
            })
            if self._source then
                if self._source.is_entity then 
                    self.texture = self._source:getDrawable()
                end
                self:frame(self._frame)
            end
            if self.psystem then 
                self.psystem:emit(n)
            end
        end,
        frame = function(self, x)
            local quads = self.quads 
            if x then 
                self._frame = x 
            end 
            if x and x > 0 and x < #self.quads + 1 then
                self.psystem:setQuads(self.quads[x])
            else 
                self.psystem:setQuads(self.quads)
            end
            return self._frame
        end,        
        source = function(self, src)
            if type(src) == 'string' then 
                src = Image(src)
            end 
            if type(src) == 'table' and src.getDrawable then
                self._source = src
                self.texture, self.quads = src:getDrawable()

                if not self.psystem then 
                    self.psystem = love.graphics.newParticleSystem(self.texture)
                else
                    self.psystem:setTexture(self.texture)
                end
                self:frame(self._frame)
            else 
                self._source = nil 
                self.texture = nil 
                self.quads = {}
            end 
        end,
        offset = function(self, x, y)
            self._offx, self._offy = x, y or x 
        end,
        _update = function(self, dt)
            if self.psystem then 
                local offx = self._offx or self._source.alignx or 0
                local offy = self._offy or self._source.aligny or 0
                self.psystem:setOffset(offx, offy)
                self.psystem:update(dt)
            end
        end,
        _draw = function(self)
            if self.psystem then 
                Game.drawObject(self, self.psystem)
            end 
        end
    }
end

--BLANKE
Blanke = nil
do
    local update_obj = Game.updateObject
    local stack = Draw.stack

    local actual_draw = function()
        Blanke.iterDraw(Game.drawables)
        State.draw()
        if Game.options.postdraw then Game.options.postdraw() end
        Physics.drawDebug()
        Hitbox.draw()
    end

    local _drawGame = function()
        Draw.push()
        Draw.reset()
        Draw.color(Game.options.background_color)
        Draw.rect('fill',0,0,Game.width,Game.height)
        Draw.pop()
        
        Background.draw()
        if Camera.count() > 0 then
            Camera.useAll(actual_draw)
        else
            actual_draw()
        end
        Foreground.draw()
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

    Blanke = {
        config = {};
        game_canvas = nil;
        loaded = false;
        scale = 1;
        padx = 0;
        pady = 0;
        load = function()
            if not Blanke.loaded then
                Blanke.loaded = true
                if not Game.loaded.all then
                    Game.load()
                end
            end
        end;
        addUpdatable = function(obj)
            obj.updatable = true
            table.insert(Game.updatables, obj)
        end;
        addDrawable = function(obj)
            local drawables = Game.drawables
            obj.drawable = true
            if obj.z and #drawables > 0 then 
                for o=1,#drawables do
                    if obj.z < drawables[o].z or o == #drawables then 
                        table.insert(drawables, o, obj)
                        return 
                    end
                end
            else 
                table.insert(drawables, obj)
            end 
        end;
        iterUpdate = function(t, dt)
            iterateEntities(t, 'updatable', function(obj)
                if obj.skip_update ~= true and obj.pause ~= true and obj._update then
                    update_obj(dt, obj)
                end
            end)
        end;
        iterDraw = function(t, override_drawable)
            local reorder_drawables = iterateEntities(t, 'drawable', function(obj)
                if obj.visible == true and obj.skip_draw ~= true and (override_drawable or obj.drawable == true) and obj.draw ~= false then
                    local obj_draw = obj._draw
                    stack(function()
                        if obj_draw then obj_draw(obj) end
                    end)
                end
            end)
        end;
        --blanke.update
        update = function(dt)
            Game.update(dt)
        end;
        --blanke.draw
        draw = function()
            if not Blanke.game_canvas then return end
            Game.is_drawing = true
            Draw.origin()

            Blanke.game_canvas:drawTo(_draw)

            Draw.push()
            Draw.color('black')
            Draw.rect('fill',0,0,Window.width,Window.height)
            Draw.pop()

            if Game.options.scale == true then
                Draw.push()
                Draw.translate(Blanke.padx, Blanke.pady)
                Draw.scale(Blanke.scale)

                Blanke.game_canvas:draw()

                Draw.pop()
            else
                Blanke.game_canvas:draw()
            end
            Game.is_drawing = false
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
        wheelmoved = function(x, y)
            Input.store('wheel', {x=x,y=y})
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
    if do_profiling and do_profiling > 0 then
        love.profiler = blanke_require('profile')
        love.profiler.start()
    else
        do_profiling = nil
    end

    Blanke.load()
end

love.frame = 0
local update = function(dt)
    if do_profiling and do_profiling > 0 then
        love.frame = love.frame + 1
        if love.frame % 100 == 0 then
            love.report = love.profiler.report(do_profiling)
            love.profiler.reset()
        end
    else
        do_profiling = nil
    end

    Blanke.update(dt)
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
end
love.resize = function(w, h) Game.updateWinSize() end
love.keypressed = function(key, scancode, isrepeat) Blanke.keypressed(key, scancode, isrepeat) end
love.keyreleased = function(key, scancode) Blanke.keyreleased(key, scancode) end
love.mousepressed = function(x, y, button, istouch, presses) Blanke.mousepressed(x, y, button, istouch, presses) end
love.mousereleased = function(x, y, button, istouch, presses) Blanke.mousereleased(x, y, button, istouch, presses) end
love.wheelmoved = function(x, y) Blanke.wheelmoved(x, y) end
love.gamepadpressed = function(joystick, button) Blanke.gamepadpressed(joystick, button) end
love.gamepadreleased = function(joystick, button) Blanke.gamepadreleased(joystick, button) end
love.joystickadded = function(joystick) Blanke.joystickadded(joystick) end
love.joystickremoved = function(joystick) Blanke.joystickremoved(joystick) end
love.gamepadaxis = function(joystick, axis, value) Blanke.gamepadaxis(joystick, axis, value) end
love.touchpressed = function(id, x, y, dx, dy, pressure) Blanke.touchpressed(id, x, y, dx, dy, pressure) end
love.touchreleased = function(id, x, y, dx, dy, pressure) Blanke.touchreleased(id, x, y, dx, dy, pressure) end
love.quit = function()
    Save.save()
    local stop = false
    if Game.forced_quit then return stop end
    local abort = function() stop = true end
    Signal.emit("Game.quit", abort)

    if not stop and do_profiling and love.report then
        local f = FS.open('profile.txt', 'w')
        f:write(love.report)
        f:close()
        FS.openURL("file://"..Save.dir().."/profile.txt")
    end

    return stop
end
--[[
local function error_printer(msg, layer)
    print(layer)
	print((debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", "")))
end

love.errhand = function(msg)
	msg = tostring(msg)

	error_printer(msg, 2)

	if not love.window or not love.graphics or not love.event then
		return
	end

	if not love.graphics.isCreated() or not love.window.isOpen() then
		local success, status = pcall(love.window.setMode, 800, 600)
		if not success or not status then
			return
		end
	end

	-- Reset state.
	if love.mouse then
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
		love.mouse.setRelativeMode(false)
	end
	if love.joystick then
		-- Stop all joystick vibrations.
		for i,v in ipairs(love.joystick.getJoysticks()) do
			v:setVibration()
		end
	end
	if love.audio then love.audio.stop() end
	love.graphics.reset()
	local font = love.graphics.setNewFont(math.floor(love.window.toPixels(14)))

	love.graphics.setBackgroundColor(89, 157, 220)
	love.graphics.setColor(255, 255, 255, 255)

	local trace = debug.traceback()

	love.graphics.clear(love.graphics.getBackgroundColor())
	love.graphics.origin()

	local err = {}

	table.insert(err, "Error\n")
	table.insert(err, msg.."\n\n")

	for l in string.gmatch(trace, "(.-)\n") do
		if not string.match(l, "boot.lua") then
			l = string.gsub(l, "stack traceback:", "Traceback\n")
			table.insert(err, l)
		end
	end

	local p = table.concat(err, "\n")

	p = string.gsub(p, "\t", "")
	p = string.gsub(p, "%[string \"(.-)\"%]", "%1")

	local function draw()
		local pos = love.window.toPixels(70)
		love.graphics.clear(love.graphics.getBackgroundColor())
		love.graphics.printf(p, pos, pos, love.graphics.getWidth() - pos)
		love.graphics.present()
	end

	while true do
		love.event.pump()

		for e, a, b, c in love.event.poll() do
			if e == "quit" then
				return
			elseif e == "keypressed" and a == "escape" then
				return
			elseif e == "touchpressed" then
				local name = love.window.getTitle()
				if #name == 0 or name == "Untitled" then name = "Game" end
				local buttons = {"OK", "Cancel"}
				local pressed = love.window.showMessageBox("Quit "..name.."?", "", buttons)
				if pressed == 1 then
					return
				end
			end
		end

		draw()

		if love.timer then
			love.timer.sleep(0.1)
		end
	end

end
]]
