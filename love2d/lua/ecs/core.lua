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

--GAME
Game = nil
do 
  Game = callable {
    options = {
      res =           'assets',
      scripts =       {},
      filter =        'linear',
      vsync =         'on',
      auto_require =  true,
      background_color = 'black',
      window_flags =  {},
      fps =           60,
      round_pixels =  false,

      auto_draw =     true,
      scale =         true,
      effect =        nil,

      load =          function() end,
      draw =          nil,
      postdraw =      nil,
      update =        function(dt) end,
    };
    config = {};
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
    __call = function(_, args)
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
          if Blanke.game_canvas then 
            Blanke.game_canvas.size = {Game.width, Game.height}
            Blanke.game_canvas:resize() 
        end
        
        local canv
        for c = 1, #CanvasStack.stack do 
            canv = CanvasStack.stack[c].value
            canv.size = {Window.width, Window.height}
            canv:resize()
        end 
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
          if Game.options.load then
              Game.options.load()
          end
          -- round pixels
          if not Game.options.round_pixels then
              floor = function(x) return x end
          end

          love.graphics.setBackgroundColor(1,1,1,0)

          Blanke.game_canvas = Canvas{draw=false}

          -- effect
          if Game.options.effect then
              Game.setEffect(unpack(Game.options.effect))
          end
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
    Add(Blanke.game_canvas, "effect", {...})
  end,
  
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
      -- TODO: uncomment
      --Physics.update(dt)
      --Timer.update(dt, dt_ms)
      if Game.options.update(dt) == true then return end
      World.update(dt)
      State.update(dt)
      State._check()
      Signal.emit('update',dt,dt_ms)
      local key = Input.pressed('_fs_toggle')
      if key and key[1].count == 1 then
          Window.toggleFullscreen()
      end
      Input.keyCheck()
      Audio.update(dt)

      --BFGround.update(dt)

      if Game.restarting then
          Game.load()
          Game.restarting = false
      end
      Game.is_updating = false
    end
  }
end 


--BLANKE
Blanke = nil
do
    local update_obj = Game.updateObject
    local stack = Draw.stack

    local actual_draw = function()
        World.draw()
        State.draw()
        if Game.options.postdraw then Game.options.postdraw() end
        -- TODO: uncomment
        --Physics.drawDebug()
        --Hitbox.draw()
    end

    local _drawGame = function()
        Draw.push()
        Draw.reset()
        Draw.color(Game.options.background_color)
        Draw.rect('fill',0,0,Game.width,Game.height)
        Draw.pop()
        
        --Background.draw()
        if Camera.count() > 0 then
            Camera.useAll(actual_draw)
        else
            actual_draw()
        end
        --Foreground.draw()
    end

    local _draw = function()
        if Game.options.draw then 
            Game.options.draw(_drawGame)
        else 
            _drawGame()
        end 
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
            if not Game.loaded.all then return end
            Game.is_drawing = true
            Draw.origin()
            
            Blanke.game_canvas:renderTo(_draw)

            Draw.push()
            Draw.color('black')
            Draw.rect('fill',0,0,Window.width,Window.height)
            Draw.pop()

            if Game.options.scale == true then
                Blanke.game_canvas.pos = {
                    Blanke.padx,
                    Blanke.pady
                }
                Blanke.game_canvas.scale = Blanke.scale
                
                Render(Blanke.game_canvas)
            else
                Render(Blanke.game_canvas)
            end
            Game.is_drawing = false
        end;
        resize = function(w, h)
            Game.updateWinSize()
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