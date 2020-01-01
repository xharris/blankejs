-- TODO Blanke.config
math.randomseed(os.time())

local bump = require "lua.bump"
local uuid = require "lua.uuid"
json = require "lua.json"
class = require "lua.clasp"
require "lua.print_r"

--UTIL.table
table.update = function (old_t, new_t, keys) 
    if keys == nil then
        for k, v in pairs(new_t) do 
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
local floor = function(x) return math.floor(x+0.5) end
Math = {
    random = function(...) return love.math.random(...) end,
    indexTo2d = function(i, col) return math.floor((i-1)%col)+1, math.floor((i-1)/col)+1 end,
    getXY = function(angle, dist) return dist * cos(rad(angle)), dist * sin(rad(angle)) end
}
--UTIL.extra
switch = function(val, choices)
    if choices[val] then choices[val]()
    elseif choices.default then choices.default() end
end
copy = function(t)
    local ret = {}
    for k,v in pairs(t) do ret[k] = v end 
    return ret
end
is_object = function(o) return type(o) == 'table' and o.init and type(o.init) == 'function' end
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
Game = nil
do
    local objects = {}
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
            auto_require =  true,
            backgroundColor = nil
        };
        config = {};
        updatables = {};
        drawables = {};
        win_width = 0;
        win_height = 0;
        width = 0;
        height = 0;

        init = function(self,args)
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
            love.filesystem.setRequirePath('?.lua;?/init.lua;lua/?/init.lua;lua/?.lua;plugins/?/init.lua;plugins/?.lua')
            -- load config.json
            config_data = love.filesystem.read('config.json')
            if config_data then Game.config = json.decode(config_data) end
            -- load settings
            Game.width, Game.height = Window.calculateSize(Blanke.config.game_size) -- game size
            Window.setSize(Blanke.config.window_size, Blanke.config.window_flags) -- window size
            Game.updateWinSize()
            if type(Game.options.filter) == 'table' then
                love.graphics.setDefaultFilter(unpack(Game.options.filter))
            else 
                love.graphics.setDefaultFilter(Game.options.filter, Game.options.filter)
            end
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
                    if FS.extname(f) == 'lua' and not table.hasValue(scripts, f) then
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
            if Game.options.backgroundColor then 
                Game.setBackgroundColor(Game.options.backgroundColor)
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

        isSpawnable = function(name)
            return objects[name] ~= nil
        end;

        spawn = function(name, args)
            local obj_info = objects[name]
            if obj_info ~= nil and obj_info.spawn_class then
                local instance = obj_info.spawn_class(obj_info.args, args, name)
                return instance
            end
        end;

        res = function(_type, file)
            return Game.options.res.."/".._type.."/"..file
        end;

        require = function(path)
            return require(path) 
        end;

        setBackgroundColor = function(...)
            return love.graphics.setBackgroundColor(Draw.parseColor(...))
        end;
    }
end

--GAMEOBJECT
GameObject = class {
    init = function(self, args, user_args)
        self.uuid = uuid()
        self.x, self.y, self.z, self.angle, self.scalex, self.scaley, self.scale = 0, 0, 0, 0, 1, 1, 1
        self.width, self.height, self.offx, self.offy, self.shearx, self.sheary = 0, 0, 0, 0, 0, 0
        self.align = nil
        self.blendmode = nil
        self.child_keys = {}
        self.parent = nil
        -- custom properties were provided
        -- so far only allowed from Entity
        if not self.classname then self.classname = "GameObject" end
        if args then
            if args.classname then self.classname = args.classname end
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
            if args.camera then
                local cam_type = type(args.camera)
                if cam_type == 'table' then
                    for _,name in ipairs(self.camera) do
                        Camera.get(name).follow = self
                    end
                else
                    Camera.get(args.camera).follow = self
                end
            end
        end
        if user_args then table.update(self,user_args) end
                    
        State.addObject(self)

        if self._spawn then self:_spawn() end
        if self.spawn then self:spawn() end
    end;
    addUpdatable = function(self)
        self.updatable = true
        table.insert(Game.updatables, self)
    end;
    addDrawable = function(self)
        self.drawable = true
        table.insert(Game.drawables, self)
        table.sort(Game.drawables, function(a, b) return a.z < b.z end)
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
    draw = function(self) 
        if self._draw then self:_draw() end 
    end;
    _update = function(self,dt) 
        if self.update then self:update(dt) end 
    end;
    destroy = function(self)
        if not self.destroyed then
            Hitbox.remove(self)
            if self._destroy then self:_destroy() end
            self.destroyed = true
            for _,k in ipairs(self.child_keys) do
                self[k]:destroy() 
            end
        end
    end;
}

--CANVAS
Canvas = GameObject:extend {
    init = function(self, w, h, settings)
        GameObject.init(self, {classname="Canvas"})
        w, h, settings = w or Game.width, h or Game.height, settings or {}
        self.auto_clear = true
        self.width = w
        self.height = h
        self.canvas = love.graphics.newCanvas(self.width, self.height, settings)
        self.blendmode = {"alpha"}
        self:addDrawable()
    end;
    _draw = function(self)  
        if not self._main_canvas then
            Draw.push()
            love.graphics.origin()
        end
        Game.drawObject(self, self.canvas)
        if not self._main_canvas then
            Draw.pop()
        end
    end;
    resize = function(self,w,h) self.canvas:resize(w,h) end;
    prepare = function(self)
        if self.auto_clear then Draw.clear() end
        -- camera transform
        love.graphics.origin()
        if Camera.transform and not self._main_canvas then
            love.graphics.replaceTransform(Camera.transform)
        end
    end;
    drawTo = function(self,obj)
        Draw.stack(function()
            -- camera transform
            if type(obj) == "function" then
                self.canvas:renderTo(function()
                    self:prepare()
                    obj()
                end)
            
            elseif is_object(obj) and obj.draw then
                self.canvas:renderTo(function()
                    self:prepare()
                    obj:draw()
                end)
            end
        end)
    end;
}

--IMAGE
Image = nil
do 
    local animations = {}
    local info_cache = {}
    Image = GameObject:extend {
        info = function(name)
            if animations[name] then return animations[name]
            else
                info = info_cache[name]
                if not info then
                    info = {}
                    info.img = love.graphics.newImage(Game.res('image',file))
                    info.w = info.img:getWidth()
                    info.h = info.img:getHeight()
                    info_cache[name] = info
                end
                return info_cache[name]
            end
        end;
        -- options: cols, rows, offx, offy, frames ('1-3',4,5), duration, durations
        animation = function(file, anims, all_opt)
            all_opt = all_opt or {}
            img = love.graphics.newImage(Game.res('image',file))
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
                for _,f in ipairs(o('frames') or {'1-'..(o('cols')*o('rows'))}) do
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
                -- animation
                args = {file=anim_info.file}
                self.animated = anim_info
                self.speed = anim_info.speed
                self.t, self.frame_index, self.frame_len = 0, 1, anim_info.durations[1] or anim_info.duration
                self.quads = anim_info.quads
                self.frame_count = #self.quads
            elseif type(args) == 'string' then
                -- static image
                args = {file=args}
            end
            self.image = love.graphics.newImage(Game.res('image',args.file))
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
    }
end

--ENTITY
local _Entity = GameObject:extend {
    init = function(self, args, spawn_args, classname)
        GameObject.init(self, args, spawn_args)

        self.hspeed = 0
        self.vspeed = 0
        self.gravity = 0
        self.gravity_direction = 90

        table.update(self, args)
        self.classname = classname
        self.imageList = {}
        self.animList = {}
        -- image
        if args.images then
            if type(args.images) == 'table' then
                for _,img in ipairs(args.images) do
                    self.imageList[img] = Image{file=img, skip_update=true}
                end
                self:_updateSize(self.imageList[args.images[1]])
            else 
                self.imageList[args.images] = Image{file=args.images, skip_update=true}
                self:_updateSize(self.imageList[args.images])
            end
            self.images = args.images
        end
        -- animation
        if args.animations then
            if type(args.animations) == 'table' then
                for _,anim_name in ipairs(args.animations) do 
                    self.animList[anim_name] = Image{file=args, animation=anim_name, skip_update=true}
                end
                self:_updateSize(self.animList[args.animations[1]])
            else 
                self.animList[args.animations] = Image{file=args, animation=args.animations, skip_update=true}
                self:_updateSize(self.animList[args.animations])
            end
        end

        if not self.defaultCollRes then
            self.defaultCollRes = 'cross'
            if args.animations or args.images then 
                self.defaultCollRes = 'slide'
            end
        end

        for _,img in pairs(self.imageList) do img.parent = self end
        for _,anim in pairs(self.animList) do anim.parent = self end
        Game.checkAlign(self)
        -- effect
        if args.effect then self:setEffect(args.effect) end
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
            Hitbox.add(self)
        end
        -- net
        if args.net and not spawn_args.net_obj then
            if not args.net_vars then 
                args.net_vars = {'x','y','animation','align'}
            end
            self.net_vars = args.net_vars
            Net.spawn(self, spawn_args)
        end
        self.net_obj = spawn_args.net_obj
        -- other props
        for _, fn in ipairs(Entity.init_props) do
            fn(self, args, spawn_args)
        end

        self:addUpdatable()
        self:addDrawable()
        if self.spawn then 
            if spawn_args then self:spawn(unpack(spawn_args))
            else self:spawn() end 
        end
        if self.body then self.body:setPosition(self.x, self.y) end
    end;
    _updateSize = function(self,obj)
        if type(self.hitArea) == "string" and (self.animList[self.hitArea] or self.imageList[self.hitArea]) then
            local other_obj = self.animList[self.hitArea] or self.imageList[self.hitArea]
            self.hitArea = {}
            self.width, self.height = abs(other_obj.width * self.scalex*self.scale), abs(other_obj.height * self.scaley*self.scale)
            Game.checkAlign(self)
            Hitbox.teleport(self)
        end
        self.width, self.height = abs(obj.width * self.scalex*self.scale), abs(obj.height * self.scaley*self.scale)
    end;
    _update = function(self,dt)
        local last_x, last_y = self.x, self.y
        if self.animation then
            assert(self.animList[self.animation], self.classname.." missing animation '"..self.animation.."'")
            self:_updateSize(self.animList[self.animation])
        end
        if self.update then self:update(dt) end
        if self.destroyed then return end
        if self.gravity ~= 0 then
            local gravx, gravy = Math.getXY(self.gravity_direction, self.gravity)
            self.hspeed = self.hspeed + gravx
            self.vspeed = self.vspeed + gravy
        end
        self.x = self.x + self.hspeed * dt
        self.y = self.y + self.vspeed * dt
        Hitbox.move(self)
        if self.body then
            local new_x, new_y = self.body:getPosition()
            if self.x == last_x then self.x = new_x end
            if self.y == last_y then self.y = new_y end
            if self.x ~= last_x or self.y ~= last_y then
                self.body:setPosition(self.x, self.y)
            end
        end
        -- image/animation update
        for name, img in pairs(self.imageList) do
            img.x, img.y = self.x, self.y
            img:update(dt)
        end
        for name, anim in pairs(self.animList) do
            anim.x, anim.y = self.x, self.y
            anim:update(dt)
        end
        Net.sync(self)
    end;
    _draw = function(self)
        if self.imageList then
            for name, img in pairs(self.imageList) do
                img:draw()
            end
        end
        if self.animation and self.animList[self.animation] then
            self.animList[self.animation]:draw()
            self.width, self.height = self.animList[self.animation].width, self.animList[self.animation].height
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

Entity = class {
    init_props = {};
    init = function(self, name, args)
        Game.addObject(name, "Entity", args, _Entity)
    end;
    addInitFn = function(fn)
        table.insert(Entity.init_props, fn)
    end
}

--INPUT
Input = nil
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
            for _,i in ipairs(inputs) do name_to_input[i] = false end
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

        mousePos = function() return love.mouse.getPosition() end;
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

    Draw = class {
        crop_used = false;
        init = function(self, instructions)
            for _,instr in ipairs(instructions) do
                name, args = instr[1], table.slice(instr,2)
                assert(Draw[name], "bad draw instruction '"..name.."'")
                Draw[name](unpack(args))
            end
        end;

        parseColor = function(...)
            args = {...}
            if Color[args[1]] then 
                args = Color[args[1]]
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
    }
    
    local draw_functions = {
        'arc','circle','ellipse','line','points','polygon','rectangle','print','printf',
        'clear','discard','origin',
        'rotate','scale','shear','translate','transformPoint',
        'setLineWidth','setPointSize'
    }
    local draw_aliases = {
        polygon = 'poly',
        rectangle = 'rect',
        setLineWidth = 'lineWidth',
        setPointSize = 'pointSize'
    }
    for _,fn in ipairs(draw_functions) do 
        Draw[draw_aliases[fn] or fn] = function(...) return love.graphics[fn](...) end 
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
    black2 =     {33,33,3}
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
        
        source = function(name, options)
            local o = opt(name)
            if not sources[name] then
                sources[name] = love.audio.newSource(Game.res('audio',o.file), o.type)
            end
            if not new_sources[name] then new_sources[name] = {} end
            local src = sources[name]:clone()
            table.insert(new_sources[name], src)
            local props = {'looping','volume','airAbsorption','pitch','relative','rolloff'}
            local t_props = {'position','attenuationDistances','cone','direction','velocity','filter','effect','volumeLimits'}
            for _,n in ipairs(props) do
                if o[n] then src['set'..string.upper(string.sub(n,1,1))..string.sub(n,2)](src,o[n]) end
            end
            for _,n in ipairs(t_props) do
                if o[n] then src['set'..string.upper(string.sub(n,1,1))..string.sub(n,2)](src,unpack(o[n])) end
            end
            return src
        end;

        play = function(...)
            local src_list = {}
            for _,name in ipairs({...}) do table.insert(src_list, Audio.source(name)) end
            love.audio.play(unpack(src_list))
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
end

--EFFECT
Effect = nil
do
    local love_replacements = {
        float = "number",
        sampler2D = "Image",
        uniform = "extern",
        texture2D = "Texel",
        gl_FragColor = "pixel",
        gl_FragCoord = "screen_coords"
    }
    local library = {}
    Effect = GameObject:extend {
        new = function(name, in_opt)
            local opt = { vars={}, unused_vars={}, integers={}, code=nil, effect='', vertex='' }
            table.update(opt, in_opt)
            -- mandatory vars
            if not opt.vars['texSize'] or opt.vars['textureSize'] then
                opt.vars['texSize'] = {Game.width, Game.height}
            end
            if not opt.vars['time'] then
                opt.vars['time'] = 0
            end
            code = ""
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

            local helper_fns = [[
    /* From glfx.js : https://github.com/evanw/glfx.js */
    float random(vec2 scale, vec2 pixelcoord, float seed) {
        /* use the fragment position for a different seed per-pixel */
        return fract(sin(dot(pixelcoord + seed, scale)) * 43758.5453 + seed);
    }
    float getX(float amt) { return amt / love_ScreenSize.x; }
    float getY(float amt) { return amt / love_ScreenSize.y; }
    ]]
            if opt.code then
                code = var_str.."\n"..helper_fns.."\n"..opt.code
            
            else
                code = var_str.."\n"..helper_fns..[[
    #ifdef VERTEX
    vec4 position(mat4 transform_projection, vec4 vertex_position) {
    ]]..opt.vertex..[[
        return transform_projection * vertex_position;
    }

    #endif

    #ifdef PIXEL
    vec4 effect(vec4 in_color, Image texture, vec2 texCoord, vec2 screen_coords){
        vec4 pixel = Texel(texture, texCoord);
    ]]..opt.effect..[[
        return pixel * in_color;
    }
    #endif]]
            end
            for old, new in pairs(love_replacements) do
                code, r = string.gsub(code, old, new)
            end
            library[name] = {
                opt = copy(opt),
                shader = love.graphics.newShader(code)
            }
        end;
        
        init = function(self, ...)
            GameObject.init(self, {classname="Effect"})

            self.names = {...}
            if type(self.names[1]) == 'table' then
                self.names = self.names[1]
            end
            for _,name in ipairs(self.names) do
                assert(library[name], "Effect :'#{name}' not found")
            end
            self.vars = {}
            for _,name in ipairs(self.names) do 
                self.vars[name] = copy(library[name].opt.vars)
            end
            self.unused_vars = {}
            for _,name in ipairs(self.names) do
                self.unused_vars[name] = copy(library[name].opt.unused_vars)
            end
            self.disabled = {}

            self.spare_canvas = Canvas()
            self.main_canvas = Canvas()
            self.spare_canvas:remDrawable()
            self.main_canvas:remDrawable()

            self:addUpdatable()
        end;

        disable = function(self, ...) 
            for _,name in ipairs({...}) do self.disabled[name] = true end 
        end;
        enable = function(self, ...)
            for _,name in ipairs({...}) do self.disabled[name] = false end
        end;
        set = function(self,name,k,v)
            self.vars[name][k] = v
        end;
        send = function(self,name,k,v)
            if not self.unused_vars[name][k] then
                library[name].shader:send(k,v)
            end
        end;
        sendVars = function(self,name)
            for k,v in pairs(self.vars[name]) do
                self:send(name, k, v)
            end
        end;
        update = function(self,dt)
            for _,name in ipairs(self.names) do
                vars = self.vars[name]
                vars.time = vars.time + dt
                self:send(name, 'time', vars.time)
            end
        end;
        draw = function(self,fn)
            self.spare_canvas:drawTo(fn)
            for _,name in ipairs(self.names) do
                if not self.disabled[name] then
                    info = library[name]
                    
                    local applyShader = function()
                        if info.opt.blend then
                            self.spare_canvas.blendmode = info.opt.blend
                        end
                        last_shader = love.graphics.getShader()
                        love.graphics.setShader(info.shader)
                        self.main_canvas:drawTo(self.spare_canvas)
                        love.graphics.setShader(last_shader)
                        self.spare_canvas:drawTo(self.main_canvas)
                    end

                    if info.opt.draw then
                        info.opt.draw(self.vars[name], applyShader)
                    end
                    self:sendVars(name)
                    applyShader()
                end
            end
            self.main_canvas:draw()
        end;
    }
end

--CAMERA
Camera = nil
do
    local default_opt = { x=0, y=0, dx=0, dy=0, angle=0, scalex=1, scaley=nil, top=0, left=0, width=nil, height=nil, follow=nil, enabled=true }
    local attach_count = 0
    local options = {}

    Camera = class {
        transform = nil;
        init = function(self, name, opt)
            opt = opt or {}
            options[name] = copy(default_opt)
            options[name].transform = love.math.newTransform()
            table.update(options[name], opt)
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
                --Draw.crop(o.x - o.left, o.y - o.top, w, h)
                o.transform:reset()
                o.transform:translate(floor(half_w), floor(half_h))
                o.transform:scale(o.scalex, o.scaley or o.scalex)
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

--MAP
Map = nil
do
    local options = {}
    local images = {} -- { name: Image }
    local quads = {} -- { hash: Quad }
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
            -- spawn entities
            for obj_uuid, info in pairs(data.objects) do
                local obj_info = getObjInfo(obj_uuid)
                if obj_info then
                    for l_uuid, coord_list in pairs(info) do
                        for _,c in ipairs(coord_list) do
                            local hb_color = Draw.hexToRgb(obj_info.color)
                            hb_color[4] = 0.25
                            local obj = new_map:_spawnEntity(obj_info.name,{
                                x=c[2], y=c[3], z=new_map:getLayerZ(layer_name[l_uuid]), layer=layer_name[l_uuid],
                                width=obj_info.size[1], height=obj_info.size[2], hitboxColor=hb_color, align="center"
                            })
                            if obj then 
                                obj.mapTag = c[1]
                            end
                        end
                    end
                end
            end
            
            new_map.data = data
            return new_map
        end;
        config = function(opt) options = opt end;
        init = function(self)
            GameObject.init(self, {classname="Map"})
            self.batches = {} -- { layer: { img_name: SpriteBatch } }
            self.hb_list = {}
            self.layer_z = {}
            self.entities = {} -- { layer: { entities... } }
            self:addDrawable()
        end;
        addTile = function(self,file,x,y,tx,ty,tw,th,layer)
            layer = layer or '_'
            -- get image
            if not images[file] then images[file] = love.graphics.newImage(file) end
            local img = images[file]
            -- get spritebatch
            if not self.batches[layer] then self.batches[layer] = {} end
            if not self.batches[layer][file] then self.batches[layer][file] = love.graphics.newSpriteBatch(img) end
            local sb = self.batches[layer][file]
            -- get quad
            local quad_hash = tx..","..ty..","..tw..","..ty
            if not quads[quad_hash] then quads[quad_hash] = love.graphics.newQuad(tx,ty,tw,th,img:getWidth(),img:getHeight()) end
            local quad = quads[quad_hash]
            local id = sb:add(quad,floor(x),floor(y),0)
            -- hitbox
            local hb_name = nil
            if options.tile_hitbox then hb_name = options.tile_hitbox[FS.removeExt(FS.basename(file))] end
            local body = nil
            local tile_info = { id=id, x=x, y=y, width=tw, height=th }
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

        _spawnEntity = function(self, ent_name, opt)
            local obj = Game.spawn(ent_name, opt)
            if obj then
                opt.layer = opt.layer or "_"
                obj:remDrawable()
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
                obj_info.layer = layer
                return self:_spawnEntity(ent_name, obj_info)
            end
        end;
        getLayerZ = function(self, l_name)
            for i, name in ipairs(options.layer_order) do
                if name == l_name then return i end
            end
            return 0
        end;
        _draw = function(self) 
            for _,l_name in ipairs(options.layer_order) do
                if self.batches[l_name] then
                    for f_name, batch in pairs(self.batches[l_name]) do
                        Game.drawObject(self, batch)
                    end
                end
                if self.entities[l_name] then 
                    for _,obj in ipairs(self.entities[l_name]) do 
                        Blanke.drawObject(obj)
                    end
                end
            end
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
    Physics = class {
        custom_grav_helpers = {};
        debug = false;
        update = function(dt)
            for name, world in pairs(worlds) do
                world:update(dt)
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
            if opt then
                world_config[name] = opt 
                table.defaults(world_config[name], {
                    gravity = 0,
                    gravity_direction = 90,
                    sleep = true
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
        joint = function(name, opt)
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
            local props = {'angularDamping','fixedRotation','bullet','inertia','linearDamping'}
            for _,p in ipairs(props) do body['set'..string.capitalize(p)](body,c[p]) end
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
                        shape = love.physics.newRectangleShape(s.offx,s.offy,s.width,s.height,s.angle)
                    end,
                    circle = function()
                        table.defaults(s, {
                            offx = 0,
                            offy = 0,
                            radius = 1
                        })
                        shape = love.physics.newCircleShape(s.offx,s.offy,s.radius)
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
                    table.insert(shapes, shape)
                end
            end
            return body, shapes
        end;
        setGravity = function(body, angle, dist)
            local helper = body:getUserData()
            helper:setGravity(angle, dist)
        end;
        draw = function(world_name)
            world_name = world_name or '_default'
            if Physics.debug then
                world = worlds[world_name]
                Draw.color(1,0,0,0.25)
                for _, body in pairs(world:getBodies()) do
                    for _, fixture in pairs(body:getFixtures()) do
                        shape = fixture:getShape()
                        if shape:typeOf("CircleShape") then
                            Draw.circle('fill', body:getWorldPoints(shape:getPoint()), shape:getRadius())
                        elseif shape:typeOf("PolygonShape") then
                            Draw.poly('fill', body:getWorldPoints(shape:getPoints()))
                        else 
                            Draw.line(body:getWorldPoints(shape:getPoints()))
                        end
                    end
                end
                Draw.color()
            end
        end;
    }

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
    }
end

--HITBOX
Hitbox = nil
do
    local world = bump.newWorld()
    local checkHitArea = function(obj)
        if obj.hasHitbox then
            if not obj.alignx then obj.alignx = 0 end
            if not obj.aligny then obj.aligny = 0 end
            if not obj.hitArea then
                obj.hitArea = {
                    left = -obj.alignx,
                    top = -obj.aligny,
                    right = 0,
                    bottom = 0
                }
            end
            table.defaults(obj.hitArea, {
                left = -obj.alignx,
                top = -obj.aligny,
                right = 0,
                bottom = 0
            })
            return obj.hitArea
        end
    end
    Hitbox = {
        debug = false;
        default_coll_response = 'slide';

        add = function(obj)
            if obj.x and obj.y and obj.width and obj.height then
                if not obj.tag then obj.tag = obj.collTag or obj.classname end
                obj.hasHitbox = true
                local ha = checkHitArea(obj)
                world:add(obj, obj.x + ha.left, obj.y + ha.top, abs(obj.width) + ha.right, abs(obj.height) + ha.bottom)  
            end
        end;     
        -- ignore collisions
        teleport = function(obj)
            if obj.hasHitbox then
                local ha = checkHitArea(obj)
                world:update(obj, obj.x + ha.left, obj.y + ha.top, abs(obj.width) + ha.right, abs(obj.height) + ha.bottom)
            end
        end;
        move = function(obj)
            if obj.hasHitbox then
                local filter = function(item, other)
                    if obj.collList and obj.collList[other.tag] then return obj.collList[other.tag] end
                    if obj.collFilter then return obj:collFilter(item, other) end
                    return obj.defaultCollRes or Hitbox.default_coll_response
                end
                local ha = checkHitArea(obj)
                local new_x, new_y, cols, len = world:move(obj, obj.x + ha.left, obj.y + ha.top, filter)
                if obj.destroyed then return end
                obj.x = new_x - ha.left
                obj.y = new_y - ha.top
                local swap = function(t, key1, key2)
                    local temp = t[key1]
                    t[key1] = t[key2]
                    t[key2] = temp
                end
                if obj.collision and len > 0 then
                    for i=1,len do
                        if obj.destroyed then return end
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
            if obj and obj.hasHitbox then 
                obj.hasHitbox = false
                world:remove(obj) 
            end 
        end;
        draw = function()
            if Hitbox.debug then
                local items, len = world:getItems()
                for _,i in ipairs(items) do
                    if i.hasHitbox and not i.destroyed then
                        Draw.color(i.hitboxColor or {1,0,0,0.25})
                        Draw.rect('fill',world:getRect(i))
                    end
                end
                Draw.color()
            end
        end;
    }
end

--STATE
State = nil
do 
    local states = {}
    local stateCB = function(name, fn_name, ...)
        local state = states[name]
        if state then 
            state.running = true
            State.curr_state = name
            if state.callbacks[fn_name] then state.callbacks[fn_name](...) end
            State.curr_state = nil
            return state
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
        start = function(name)
            local state = states[name]
            if state and not state.running then
                stateCB(name, 'enter')
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
                    stateCB(name, 'draw')
                end
            end
        end,
        stop = function(name) 
            if name then
                local state = states[name]
                if state and state.running then
                    state = stateCB(name, 'leave')
                    for _,obj in ipairs(state.objects) do 
                        if obj then obj:destroy() end 
                    end
                    state.running = false
                end
            else 
                for name, state in pairs(states) do 
                    State.stop(name)
                end
            end
        end,
        switch = function(name)
            State.stop()
            State.start(name)
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

--NET
Net = nil
do
    local socket = require "socket"
    local uuid = require "lua.uuid"
    require "lua.noobhub"
    local client
    local leader = false
    local net_objects = {}

    local destroyNetObjects = function(clientid)
        if net_objects[clientid] then 
            for objid, obj in pairs(net_objects[clientid]) do 
                if not obj.net_persistent then 
                    obj:destroy()
                    net_objects[clientid][objid] = nil
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
        elseif data.type == "data" then
            Signal.emit('net.data', netdata, data)
        end
    end

    local onFail = function()

    end

    local prepNetObject = function(obj)
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
        ip='',
        client=nil,
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
            sendData(data)
        end,
        on = function(event, fn)
            Signal.on('net.'..event, fn)
        end,
        spawn = function(obj, args)
            prepNetObject(obj)
            -- trash function arguments
            args = args or {}
            for prop, val in pairs(args) do
                if type(val) == 'function' then args[prop] = nil end
            end
            args.net_id = obj.net_id
            sendNetEvent('obj.spawn', {
                clientid = Net.id,
                classname = obj.classname,
                args = args
            })
            Net.sync(obj)
        end,
        -- only to be used with class instances. will not sync functions?/table data (TODO: sync functions too?)
        sync = function(obj, vars) 
            if not obj then 
                for objid, obj in pairs(net_objects[Net.id]) do 
                    Net.sync(obj)
                end
                return
            end
            prepNetObject(obj)
            local net_vars = vars or obj.net_vars or {}
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
            if leader then 
                local sync_objs = {}
                for clientid, objs in pairs(net_objects) do 
                    sync_objs[clientid] = {}
                    for objid, obj in pairs(objs) do
                        if obj and not obj.destroyed then  
                            sync_objs[clientid][objid] = { classname=obj.classname, net_id=objid, net_obj=true }
                            for _,prop in ipairs(obj.net_vars) do 
                                sync_objs[clientid][objid][prop] = obj[prop]
                            end
                        end
                    end
                end
                sendNetEvent('obj.syncAll', {
                    clientid = Net.id,
                    targetid = targetid,
                    sync_objs = sync_objs
                })
            end
        end
    }

    local s = socket.udp()
    s:setpeername("74.125.115.104",80)
    local ip, _ = s:getsockname()
    Net.ip = ip
end

--WINDOW
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
    setSize = function(r, flags)
        local w, h = Window.calculateSize(r)
        love.window.setMode(w, h, flags)
    end;
    setExactSize = function(w, h, flags)
        love.window.setMode(w, h, flags)
    end;
    calculateSize = function(r)
        r = r or 3
        if not Window.aspect_ratio then Window.aspectRatio() end
        local w = Window.resolutions[r]
        local h = w / Window.aspect_ratio[1] * Window.aspect_ratio[2]
        return w, h
    end;
    fullscreen = function(v,fs_type)
        if not v then return love.window.getFullscreen()
        else love.window.setFullscreen(v,fs_type) end
    end;
    toggleFullscreen = function()
        return Window.fullscreen(not Window.fullscreen())
    end
}

--BLANKE
Blanke = nil
do 
    local iterate = function(t, test_val, fn) 
        local len = #t
        local offset = 0
        for o = 1, len do
            local obj = t[o]
            if obj then 
                if obj.destroyed or not obj[test_val] then 
                    t[o] = nil
                    offset = offset + 1
                else
                    t[o] = nil 
                    t[o - offset] = obj
                    fn(obj, o)
                end
            end
        end
    end

    Blanke = {
        config = {};
        game_canvas = nil;
        loaded = false;
        load = function()
            if not Blanke.loaded then
                Blanke.loaded = true
                Game.load()
            end
        end;
        iterUpdate = function(t, dt) 
            iterate(t, 'updatable', function(obj)
                if not obj.skip_update and not obj.pause and obj._update then
                    obj:_update(dt)
                end
            end)
        end;
        iterDraw = function(t, override_drawable)
            iterate(t, 'drawable', function(obj)
                if not obj.skip_draw and (override_drawable or obj.drawable) and obj.draw ~= false then
                    Blanke.drawObject(obj)
                end
            end)
        end;
        drawObject = function(obj)
            Draw.stack(function()
                if obj.draw then 
                    obj:draw(function()
                        if obj._draw then obj:_draw() end
                    end)
                elseif obj._draw then obj:_draw() end
            end)
        end;
        update = function(dt)
            if Game.options.update(dt) == true then return end
            Physics.update(dt)
            Blanke.iterUpdate(Game.updatables, dt)
            State.update(dt)
            Signal.emit('update',dt)
            local key = Input.pressed('_fs_toggle') 
            if key and key.count == 1 then
                Window.toggleFullscreen()
            end            
            Input.keyCheck()
        end;    
        draw = function()
            local actual_draw = function()
                Blanke.iterDraw(Game.drawables)
                if Game.options.postDraw then Game.options.postDraw() end
                Physics.draw()
                Hitbox.draw()

                State.draw()
            end

            local _drawGame = function()
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
            if Blanke.config.scale == true then
                local scalex, scaley = Game.win_width / Game.width, Game.win_height / Game.height
                local scale = math.min(scalex, scaley)
                local padx, pady = 0, 0
                if scalex > scaley then
                    padx = floor((Game.win_width - (Game.width * scale)) / 2)
                else 
                    pady = floor((Game.win_height - (Game.height * scale)) / 2)
                end
                Draw.push()
                Draw.translate(padx, pady)
                Draw.scale(scale)
                Blanke.game_canvas:draw()
                Draw.pop()
            
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
    }
end


love.load = function() Blanke.load() end
love.update = function(dt) 
    Blanke.update(dt)
end
love.draw = function() Blanke.draw() end
love.resize = function(w, h) Game.updateWinSize() end
love.keypressed = function(key, scancode, isrepeat) Blanke.keypressed(key, scancode, isrepeat) end
love.keyreleased = function(key, scancode) Blanke.keyreleased(key, scancode) end
love.mousepressed = function(x, y, button, istouch, presses) Blanke.mousepressed(x, y, button, istouch, presses) end
love.mousereleased = function(x, y, button, istouch, presses) Blanke.mousereleased(x, y, button, istouch, presses) end
-- from https://github.com/adnzzzzZ/STALKER-X
love.run = function()
  if love.math then love.math.setRandomSeed(os.time()) end
  if love.load then love.load(arg) end
  if love.timer then love.timer.step() end

  local dt = 0
  local fixed_dt = 1/60
  local accumulator = 0

  while true do
    if love.event then
      love.event.pump()
      for name, a, b, c, d, e, f in love.event.poll() do
        if name == "quit" then
          if not love.quit or not love.quit() then
            return a
          end
        end
        love.handlers[name](a, b, c, d, e, f)
      end
    end
    if love.timer then
      love.timer.step()
      dt = love.timer.getDelta()
    end

    accumulator = accumulator + dt
    while accumulator >= fixed_dt do
      if love.update then love.update(fixed_dt) end
      accumulator = accumulator - fixed_dt
    end
    if love.graphics and love.graphics.isActive() then
      love.graphics.clear(love.graphics.getBackgroundColor())
      love.graphics.origin()
      if love.draw then love.draw() end
      love.graphics.present()
    end

    if love.timer then love.timer.sleep(0.0001) end
  end
end