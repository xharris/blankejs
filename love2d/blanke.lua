local bump = require "bump"
local uuid = require "uuid"
local json = require "json"
local class = require "clasp"

--UTIL.table
table.update = function (old_t, new_t, keys) 
    if keys == nil then
        for k, v in pairs(new_t) do 
            print(k,v)
            old_t[k] = v 
        end
    else
        for _,k in ipairs(keys) do if new_t[k] ~= nil then old_t[k] = new_t[k] end end
    end
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
--UTIL.string
string.contains = function (str,q) 
    return string.match(str, q) ~= nil
end
string.capitalize = function (str) 
    return string.upper(string.sub(str,1,1))..string.sub(str,2)
end
--UTIL.math
local sin, cos, rad, deg, abs = math.sin, math.cos, math.rad, math.deg, math.abs

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

--GAME
Game = class {
    options = {
        res =           'assets',
        scripts =       {},
        filter =        'linear',
        load =          function() end,
        update =        function(dt) end,
        draw =          function(d) d() end,
        postDraw =      nil,
        effect =        nil,
        auto_require =  true
    };
    config = {};
    objects = {};
    updatables = {};
    drawables = {};
    win_width = 0;
    win_height = 0;
    width = 0;
    height = 0;

    init = function(args)
        table.update(Game.options, args)
        --Game.load()
        return nil
    end;

    updateWinSize = function()
        Game.win_width, Game.win_height, flags = love.window.getMode()
        if not Blanke.config.scale then
            Game.width, Game.height = Game.win_width, Game.win_height
        end
    end;
    
    load = function()
        -- load config.json
        config_data = love.filesystem.read('config.json')
        if config_data then Game.config = json.decode(config_data)
        -- load settings
        Game.width, Game.height = Window.calculateSize(Blanke.config.game_size) -- game size
        Window.setSize(Blanke.config.window_size, Blanke.config.window_flags) -- window size
        Game.updateWinSize()
        if type(Game.options.filter) == 'table' then
            love.graphics.setDefaultFilter(unpack(Game.options.filter))
        else 
            love.graphics.setDefaultFilter(Game.options.filter, Game.options.filter)
        end
        -- load scripts
        scripts = Game.options.scripts or {}
        if Game.options.auto_require then
            files = FS.ls ''
            for _,f in ipairs(files) do
                if FS.extname(f) == 'moon' and not table.hasValue(scripts, f) then
                    new_f = FS.removeExt(f)
                    table.insert(scripts, new_f)
                end
            end
        end
        for _,script in ipairs(scripts) do Game.require(script) end
        -- fullscreen toggle
        Input({ _fs_toggle = { 'alt', 'enter' } }, { 
            combo = { '_fs_toggle' },
            no_repeat = { '_fs_toggle' },
        })
        -- effect
        if Game.options.effect then
            Game.effect = Effect(Game.options.effect)
        end
        if Game.options.load then
            Game.options.load()
        end

        Blanke.game_canvas = Canvas()
        Blanke.game_canvas._main_canvas = true
        Blanke.game_canvas:remDrawable()
    end;

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
        local ax, ay = 0, 0
        if obj.align then
            if string.contains(obj.align, 'center') then
                ax = obj.width/2 
                ay = obj.height/2
            end
            if string.contains(obj.align,'left') then
                ax = 0
            end
            if string.contains(obj.align, 'right') then
                ax = obj.width
            end
            if string.contains(obj.align, 'top') then
                ay = 0
            end
            if string.contains(obj.align, 'bottom') then
                ay = obj.height
            end
        end
        obj.alignx, obj.aligny = ax, ay
    end;

    drawObject = function(gobj, ...)
        local props = gobj
        if gobj.parent then props = gobj.parent end
        local lobjs = {...}
        
        local draw = function()
            last_blend = nil
            if props.blendmode then
                last_blend = Draw.getBlendMode()
                Draw.setBlendMode(unpack(props.blendmode))
            end
            for _,lobj in ipairs(lobjs) do
                Game.checkAlign(props)
                local ax, ay = props.alignx, props.aligny
                if gobj.quad then 
                    love.graphics.draw(lobj, gobj.quad, floor(props.x), floor(props.y), math.rad(props.angle), props.scalex * props.scale, props.scaley * props.scale,
                        floor(props.offx + props.alignx), floor(props.offy + props.aligny), props.shearx, props.sheary)
                else
                    love.graphics.draw(lobj, floor(props.x), floor(props.y), math.rad(props.angle), props.scalex * props.scale, props.scaley * props.scale,
                        floor(props.offx + props.alignx), floor(props.offy + props.aligny), props.shearx, props.sheary)
                end
            end
            if last_blend then
                Draw.setBlendMode(last_blend)
            end
        end

        if props.effect then 
            props.effect:draw(draw)
        else 
            draw()
        end
    end;

    isSpawnable = function(name) return objects[name] ~= nil end;

    spawn = function(name, args)
        local obj_info = objects[name]
        if obj_info ~= nil and obj_info.spawn_class then
            local instance = obj_info.spawn_class(obj_info.args, args, name)
            return instance
        end
    end;

    res = function(_type, file) return "#{Game.options.res}/#{_type}/#{file}" end;

    require = function(path) return require(path) end;

    setBackgroundColor = function(...) return love.graphics.setBackgroundColor(Draw.parseColor(...)) end;
}
