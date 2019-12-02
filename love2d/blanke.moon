-- Hitbox, Physics (contact, masks)
import is_object, p, copy from require "moon"
bump = require 'bump'

--UTIL.table
table.update = (old_t, new_t, keys) -> 
    if keys == nil then
        for k, v in pairs new_t do old_t[k] = v
    else
        for k in *keys do if new_t[k] ~= nil then old_t[k] = new_t[k]
table.keys = (t) -> [k for k, v in pairs t]
table.every = (t) ->
    for k,v in pairs(t) do if not v then return false
    return true
table.some = (t) ->
    for k,v in pairs(t) do if v then return true
    return false
table.len = (t) -> 
    c = 0
    for k,v in pairs(t) do c += 1
    return c
table.hasValue = (t, val) ->
    for k,v in pairs(t) do if v == val return true 
    return false
table.slice = (t, start, finish) ->
    i, res, finish = 1, {}, finish or table.len(t)
    for j = start, finish
        res[i] = t[j]
        i += 1
    return res
table.defaults = (t,defaults) ->
    for k,v in pairs(defaults)
        if t[k] == nil then t[k] = v
        else if type(v) == 'table' then table.defaults(t[k],defaults[k])
         
--UTIL.string
string.contains = (str,q) -> (string.match(str, q) ~= nil)
string.capitalize = (str) -> string.upper(string.sub(str,1,1))..string.sub(str,2)

--UTIL.math
import sin, cos, rad, deg from math
floor = (x) -> math.floor(x+0.5)
export Math = {
    random: (...) -> love.math.random(...)
    indexTo2d: (i, col) -> math.floor((i-1)%col)+1, math.floor((i-1)/col)+1
    getXY: (angle, dist) -> dist * cos(rad(angle)), dist * sin(rad(angle))
}

export FS = {
    basename: (str) -> string.gsub(str, "(.*/)(.*)", "%2")
    dirname: (str) -> if string.match(str,".-/.-") then return string.gsub(str, "(.*/)(.*)", "%1") else return ''
    extname: (str) -> if str = string.match(str,"^.+(%..+)$") then return string.sub(str,2)
}

-- needed extra libraries
uuid = require "uuid"
json = require "json"
HC = require "HC"

--GAME
export class Game
    @options = {
        res: 'assets',
        filter: 'linear'
        load: () ->
        update: (dt) ->
        draw: nil
        postDraw: nil
    }
    @config = {

    }
    
    objects = {}
    @updatables = {}
    @drawables = {}
    @width = 0
    @height = 0

    @graphics = {
        clear: (...) -> love.graphics.clear(...)
    }

    new: (args) =>
        table.update(@@options, args, {'res','filter','load','draw','update','postDraw'})
        return nil

    @updateWinSize = () ->
        @width, @height = love.graphics.getDimensions()

    @load = () ->
        -- load config.json
        config_data = love.filesystem.read('config.json')
        if config_data then @@config = json.decode(config_data)
        @@updateWinSize!
        if type(Game.filter) == 'table'
            love.graphics.setDefaultFilter(unpack(Game.options.filter))
        else 
            love.graphics.setDefaultFilter(Game.options.filter, Game.options.filter)
        if @options.load then @options.load()

    @addObject = (name, _type, args, spawn_class) ->
        -- store in object 'library' and update initial props
        if objects[name] == nil then 
            objects[name] = {
                type: _type
                :args
                :spawn_class
            }

    @drawObject = (gobj, ...) ->
        props = gobj
        if gobj.parent then props = gobj.parent
        lobjs = {...}
        
        draw = () ->
            last_blend = nil
            if props.blendmode then
                last_blend = Draw.getBlendMode()
                Draw.setBlendMode(unpack(props.blendmode))
            for lobj in *lobjs
                ax, ay = 0, 0
                if props.align then
                    if string.contains(props.align, 'center')
                        ax = gobj.width/2 
                        ay = gobj.height/2
                    if string.contains(props.align,'left')
                        ax = 0
                    if string.contains(props.align, 'right')
                        ax = gobj.width
                    if string.contains(props.align, 'top')
                        ay = 0
                    if string.contains(props.align, 'bottom')
                        ay = gobj.height
                if gobj.quad then 
                    love.graphics.draw lobj, gobj.quad, props.x, props.y, math.rad(props.angle), props.scalex * props.scale, props.scaley * props.scale,
                        props.offx + ax, props.offy + ay, props.shearx, props.sheary
                else
                    love.graphics.draw lobj, props.x, props.y, math.rad(props.angle), props.scalex * props.scale, props.scaley * props.scale,
                        props.offx + ax, props.offy + ay, props.shearx, props.sheary
            if last_blend
                Draw.setBlendMode(last_blend)

        if props.effect then 
            props.effect\draw draw 
        else 
            draw!

    @isSpawnable: (name) -> objects[name] ~= nil

    @spawn: (name, args) ->
        obj_info = objects[name]
        if obj_info ~= nil and obj_info.spawn_class
            instance = obj_info.spawn_class(obj_info.args, args, name)
            return instance

    @res: (_type, file) -> "#{Game.options.res}/#{_type}/#{file}"

    @setBackgroundColor: (...) -> love.graphics.setBackgroundColor(...)

--GAMEOBJECT
export class GameObject 
    new: (args, user_args) =>
        @uuid = uuid()
        @x, @y, @z, @angle, @scalex, @scaley, @scale = 0, 0, 0, 0, 1, 1, 1
        @width, @height, @offx, @offy, @shearx, @sheary = 0, 0, 0, 0, 0, 0
        @align = nil
        @blendmode = nil
        @child_keys = {}
        @parent = nil
        -- custom properties were provided
        -- so far only allowed from Entity
        if args then
            for k, v in pairs args
                arg_type = type(v)
                new_obj = nil
                -- instantiation w/o args
                if arg_type == "string" and Game.isSpawnable(v)
                    new_obj = Game.spawn(v)
                else if is_object(v)
                    table.insert(@child_keys, k)
                    new_obj = v!
                else if arg_type == "table" then
                    -- instantiation with args
                    if type(v[1]) == "string"
                        new_obj = Game.spawn(v[1], table.slice(v, 2))
                    else if is_object(v[1])
                        table.insert(@child_keys, k)
                        new_obj = v[1](unpack(table.slice(v, 2)))
                if new_obj
                    @[k] = new_obj
                    args[k] = nil
                    
            if args.camera then
                @cam_type = type args.camera
                if @cam_type == 'table' then
                    for name in *@camera do
                        Camera.get(name).follow = @
                else
                    Camera.get(args.camera).follow = @
        if user_args then table.update(@,user_args)
                    
        if @_spawn then @\_spawn()
        if @spawn then @\spawn()
    addUpdatable: () =>
        @updatable = true
        table.insert(Game.updatables, @)
    addDrawable: () =>
        @drawable = true
        table.insert(Game.drawables, @)
        table.sort(Game.drawables, (a, b) -> a.z < b.z)
    remUpdatable: () =>
        @updatable = false
    remDrawable: () =>
        @drawable = false
    setEffect: (...) => 
        @effect = Effect(...)
    draw: () => if @_draw then @\_draw!
    _update: (dt) => if @update then @update dt
    destroy: () =>
        @destroyed = true
        for k in *@child_keys
            self[k]\destroy() 

--CANVAS
export class Canvas extends GameObject
    new: (w=Game.width, h=Game.height, settings={}) =>
        super!
        @angle = 0
        @auto_clear = true
        @width = w
        @height = h
        @canvas = love.graphics.newCanvas(@width, @height, settings)
        @addDrawable!
    _draw: () => Game.drawObject(@, @canvas)
    resize: (w,h) => @canvas\resize(w,h)
    drawTo: (obj) =>
        last_canvas = love.graphics.getCanvas()
        Draw.stack () ->
            Draw.setBlendMode('alpha')
            love.graphics.setCanvas(@canvas)
            if @auto_clear then Draw.clear()
            if type(obj) == "function"
                obj!
            else if is_object(obj) and obj.draw
                obj\draw!
            love.graphics.setCanvas(last_canvas)

--IMAGE
export class Image extends GameObject
    animations = {}
    info_cache = {}
    @info = (name) ->
        if animations[name] then return animations[name]
        else
            info = info_cache[name]
            if not info
                info = {}
                info.img = love.graphics.newImage(Game.res('image',file))
                info.w = info.img\getWidth!
                info.h = info.img\getHeight!
                info_cache[name] = info
            return info_cache[name]
    @animation = (file, anims, all_opt={}) ->
        img = love.graphics.newImage(Game.res('image',file))
        for anim in *anims
            o = (k) -> anim[k] or all_opt[k]
            quads, durations = {}, {}
            fw, fh = img\getWidth! / o('cols'), img\getHeight! / o('rows')
            offx, offy = o('offx') or 0, o('offy') or 0
            -- calculate frame list
            frame_list = {}
            for f in *o('frames')
                f_type = type(f)
                if f_type == 'number'
                    table.insert(frame_list, f)
                else if f_type == 'string'
                    a,b = string.match(f,'%s*(%d+)%s*-%s*(%d+)%s*')
                    for i = a,b
                        table.insert(frame_list, i)
            -- make quads
            for f in *frame_list
                x,y = Math.indexTo2d(f, o('cols'))
                table.insert(quads, love.graphics.newQuad((x-1)*fw,(y-1)*fh,fw,fh,img\getWidth!,img\getHeight!))
            animations[anim.name] = {file:file, duration:o('duration'), durations:o('durations') or {}, quads:quads, w:fw, h:fh, frame_size:{fw,fh}}
    new: (args) =>
        super!
        -- animation?
        anim_info = nil
        if type(args) == 'string' then
            anim_info = animations[args]
        else if args.animation
            anim_info = animations[args.animation]

        if anim_info then 
            args = {file:anim_info.file}
            @animated = anim_info
            @t, @frame_index, @frame_len = 0, 1, anim_info.durations[1] or anim_info.duration
            @quads = anim_info.quads
        else
            args = {file:args}
        @image = love.graphics.newImage(Game.res('image',args.file))
        @updateSize!
        if @_spawn then @\_spawn()
        if @spawn then @\spawn()
        if not args.skip_update then 
            @addUpdatable!
        if args.draw == true
            @addDrawable!
    updateSize: () =>
        if @animated then 
            @width, @height = @animated.frame_size[1] * @scalex * @scale, @animated.frame_size[2] * @scaley * @scale
        else
            @width = @image\getWidth() * @scalex * @scale
            @height = @image\getHeight() * @scaly * @scale
    update: (dt) => 
        -- update animation
        if @animated
            @t += dt
            if @t > @frame_len
                @frame_index += 1
                if @frame_index > #@quads then @frame_index = 1
                info = @animated
                @frame_len = info.durations[tostring(@frame_index)] or info.duration
                @t = 0
            @quad = @quads[@frame_index]
    _draw: () => 
        @x, @y = floor(@x), floor(@y)
        @updateSize!
        Game.drawObject(@, @image)

--ENTITY
export class _Entity extends GameObject
    new: (args, spawn_args, classname) =>
        super args, spawn_args

        @gravity = 0
        @gravity_direction = 90

        table.update(@, args)
        @classname = classname
        @imageList = {}
        @animList = {}
        -- image
        if args.images
            if type(args.images) == 'table'
                @imageList = {img, Image {file: img, skip_update: true} for img in *args.images}
                @_updateSize(@imageList[args.images[1]])
            else 
                @imageList = {[args.images]: Image {file: args.images, skip_update: true}}
                @_updateSize(@imageList[args.images])
            @images = args.images
        -- animation
        if args.animations
            if type(args.animations) == 'table'
                @animList = {anim_name, Image {file: args, animation: anim_name, skip_update: true} for anim_name in *args.animations}
                @_updateSize(@animList[args.animations[1]])
            else 
                @animList = {[args.animations]: Image {file: args, animation: args.animations, skip_update: true} }
                @_updateSize(@animList[args.animations])
        for _,img in pairs(@imageList) do img.parent = @
        for _,anim in pairs(@animList) do anim.parent = @
        -- effect
        if args.effect
            if type(args.effect) == 'table'
                @setEffect unpack(args.effect)
            else 
                @setEffect args.effect
        -- physics
        assert(not (args.body and args.fixture), "Entity can have body or fixture. Not both!")
        if args.body
            Physics.body @classname, args.body
            @body = Physics.body @classname
        if args.joint
            Physics.joint @classname, args.joint
            @joint = Physics.joint @classname

        @addUpdatable!
        @addDrawable!
        if @spawn then 
            if spawn_args then @spawn unpack(spawn_args)
            else @spawn!
        if @body then @body\setPosition @x, @y
    
    _updateSize: (obj) =>
        @width, @height = obj.width * @scalex*@scale, obj.height * @scaley*@scale
    _update: (dt) =>
        last_x, last_y = @x, @y
        if @animation 
            @_updateSize(@animList[@animation])
        if @update then @update(dt)
        if @body
            new_x, new_y = @body\getPosition!
            if @x == last_x then @x = new_x
            if @y == last_y then @y = new_y
            if @x ~= last_x or @y ~= last_y
                @body\setPosition @x, @y
        -- image/animation update
        for name, img in pairs(@imageList)
            img.x, img.y = @x, @y
            img\update dt
        for name, anim in pairs(@animList)
            anim.x, anim.y = @x, @y
            anim\update dt
    _draw: () =>
        if @imageList
            for name, img in pairs(@imageList)
                img\draw!
        if @animation and @animList[@animation]
            @animList[@animation]\draw!
            @width, @height = @animList[@animation].width, @animList[@animation].height

Entity = (name, args) ->
    Game.addObject(name, "Entity", args, _Entity)

--INPUT
export class Input
    name_to_input = {} -- name -> { key1: t/f, mouse1: t/f }
    input_to_name = {} -- key -> { name1, name2, ... }
    options = {
        norepeat: {}
        combo: {}
    }
    pressed = {}
    released = {}

    new: (inputs, _options) =>
        for name, inputs in pairs(inputs)
            Input.addInput(name, inputs, _options)
        table.update(options, _options)
        return nil

    @addInput = (name, inputs, options) ->
        name_to_input[name] = { i,false for i in *inputs }
        for i in *inputs
            if not input_to_name[i] then input_to_name[i] = {}
            if not table.hasValue(input_to_name[i], name) then table.insert(input_to_name[i], name)

    @pressed = (name) -> pressed[name]

    @released = (name) -> released[name]

    @press = (key, extra) ->
        if input_to_name[key] 
            for name in *input_to_name[key]
                name_to_input[name][key] = true
                -- is input pressed now?
                combo = table.hasValue(options.combo, name)
                if (combo and table.every(name_to_input[name])) or (not combo and table.some(name_to_input[name]))
                        pressed[name] = extra

    @release = (key, extra) ->
        if input_to_name[key]
            for name in *input_to_name[key]
                name_to_input[name][key] = false
                -- is input released now?
                combo = table.hasValue(options.combo, name)
                if pressed[name] and (combo or not table.some(name_to_input[name]))
                        pressed[name] = false
                        released[name] = extra
    
    @releaseCheck = () -> released = {}

--DRAW
export class Draw
    crop_used = false
    new: (instructions) =>
        for instr in *instructions
            name, args = instr[1], table.slice(instr,2)
            assert(Draw[name], "bad draw instruction '#{name}'")
            Draw[name](unpack(args))
    @color = (...) ->
        if #{...} == 0 then
            love.graphics.setColor(1,1,1,1)
        else 
            love.graphics.setColor(...)

    @getBlendMode = () -> love.graphics.getBlendMode()
    @setBlendMode = (...) -> love.graphics.setBlendMode(...)
    @crop = (x,y,w,h) ->
        stencilFn = () -> Draw.rect('fill',x,y,w,h)
        love.graphics.stencil(stencilFn,"replace",1)
        love.graphics.setStencilTest("greater",0)
        crop_used = true
    @reset = (only) ->
        if only == 'color' or not only
            Draw.color(1,1,1,1)
            Draw.lineWidth(1)
        if only == 'transform' or not only
            Draw.origin()
        if (only == 'crop' or not only) and crop_used
            crop_used = false
            love.graphics.setStencilTest()
    @push = () -> love.graphics.push('all')
    @pop = () -> 
        Draw.reset('crop')
        love.graphics.pop()
    @stack = (fn) ->
        Draw.push()
        fn!
        Draw.pop()

draw_functions = {'arc','circle','clear','discard','ellipse','line','points','polygon','rectangle','setLineWidth','origin','print','printf'}
draw_aliases = {
    polygon: 'poly',
    rectangle: 'rect',
    setLineWidth: 'lineWidth'
}
for fn in *draw_functions do Draw[draw_aliases[fn] or fn] = (...) -> love.graphics[fn](...)

--AUDIO
export class Audio
    default_opt = {
        type: 'static'
    }
    defaults = {}
    sources = {}
    new_sources = {}

    opt = (name, overrides) ->
        if not defaults[name] then Audio name, {}
        return defaults[name]

    new: (file, ...) =>
        option_list = {...}
        for options in *option_list
            store_name = options.name or file
            options.file = file
            if not defaults[store_name] then defaults[store_name] = {}
            new_tbl = copy(default_opt)
            table.update(new_tbl, options)
            table.update(defaults[store_name], new_tbl)
    
    @source = (name, options) ->
        o = opt(name)
        if not sources[name] then
            sources[name] = love.audio.newSource(Game.res('audio',o.file), o.type)
        if not new_sources[name] then new_sources[name] = {}
        src = sources[name]\clone()
        table.insert(new_sources[name], src)
        props = {'looping','volume','airAbsorption','pitch','relative','rolloff'}
        t_props = {'position','attenuationDistances','cone','direction','velocity','filter','effect','volumeLimits'}
        for n in *props
            if o[n] then src['set'..string.upper(string.sub(n,1,1))..string.sub(n,2)](src,o[n])
        for n in *t_props
            if o[n] then src['set'..string.upper(string.sub(n,1,1))..string.sub(n,2)](src,unpack(o[n]))
        return src

    @play = (...) -> love.audio.play(unpack([ Audio.source(name) for name in *{...} ]))
    @stop = (...) -> 
        names = {...}
        if #names == 0 then love.audio.stop()
        else
            for n in *names
                if new_sources[n] then for src in *new_sources[n] do love.audio.stop(src)
    @isPlaying = (name) -> 
        if new_sources[name] then return table.some([ src\isPlaying! for src in *new_sources[name] ])

--EFFECT
export class Effect
    love_replacements = {
        float: "number",
        sampler2D: "Image",
        uniform: "extern",
        texture2D: "Texel",
        gl_FragColor: "pixel",
        gl_FragCoord: "screen_coords"
    }
    library = {}
    @new = (name, in_opt) ->
        opt = { vars:{}, unused_vars:{}, integers:{}, code:nil, effect:'', vertex:'' }
        table.update(opt, in_opt)
        code = ""
        -- create var string
        var_str = ""
        for key, val in pairs(opt.vars)
            -- unused vars?
            if not string.contains(opt.code or (opt.effect..' '..opt.vertex), key) then
                opt.unused_vars[key] = true
            -- get var type
            switch type(val)
                when 'table'
                    var_str ..= "uniform vec"..tostring(#val).." "..key..";\n"
                when 'number'
                    if table.hasValue(opt.integers, key)
                        var_str ..= "uniform int "..key..";\n"
                    else
                        var_str ..= "uniform float "..key..";\n"
                when 'string'
                    if val == "Image"
                        var_str ..= "uniform Image "..key..";\n"
        helper_fns = "
/* From glfx.js : https://github.com/evanw/glfx.js */
float random(vec2 scale, vec2 pixelcoord, float seed) {
    /* use the fragment position for a different seed per-pixel */
    return fract(sin(dot(pixelcoord + seed, scale)) * 43758.5453 + seed);
}
float getX(float amt) { return amt / love_ScreenSize.x; }
float getY(float amt) { return amt / love_ScreenSize.y; }
"
        if opt.code then
            code = var_str.."
"..helper_fns.."
"..opt.code
        
        else
            code = var_str.."
"..helper_fns.."
#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position) {
"..opt.vertex.."
    return transform_projection * vertex_position;
}

#endif

#ifdef PIXEL
vec4 effect(vec4 in_color, Image texture, vec2 texCoord, vec2 screen_coords){
    vec4 pixel = Texel(texture, texCoord);
"..opt.effect.."
    return pixel * in_color;
}
#endif"
        for old, new in pairs(love_replacements)
            code, r = string.gsub(code, old, new)
       -- print code
        library[name] = {
            opt: copy(opt)
            shader: love.graphics.newShader(code)
        }
    
    new: (...) =>
        @names = {...}
        assert(library[name], "Effect \'#{name}\' not found") for name in *@names
        @vars = { name, copy(library[name].opt.vars) for name in *@names }
        @unused_vars = { name, copy(library[name].opt.unused_vars) for name in *@names }
        @disabled = {}

        @spare_canvas = Canvas!
        @main_canvas = Canvas!
        @spare_canvas.blendmode = {"alpha","premultiplied"}
        @main_canvas.blendmode = {"alpha","premultiplied"}
        @spare_canvas\remDrawable!
        @main_canvas\remDrawable!

    disable: (...) => for name in *{...} do @disabled[name] = true
    enable: (...) => for name in *{...} do @disabled[name] = false
    set: (name,k,v) =>
        @vars[name][k] = v
    send: (name,k,v) =>
        library[name].shader\send(k,v) if not @unused_vars[name][k]
    sendVars: (name) =>
        for k,v in pairs(@vars[name])
            @send(name, k, v)
    draw: (fn) =>
        @spare_canvas\drawTo fn
        for name in *@names
            if not @disabled[name]
                info = library[name]
                
                applyShader = () ->
                    if info.opt.blend
                        @spare_canvas.blendmode = info.opt.blend
                    last_shader = love.graphics.getShader()
                    love.graphics.setShader(info.shader)
                    @main_canvas\drawTo @spare_canvas
                    love.graphics.setShader(last_shader)

                if info.opt.draw
                    info.opt.draw(@vars[name], applyShader)
                @sendVars name
                applyShader!

        @main_canvas\draw!

--CAMERA
export class Camera
    default_opt = { x:0, y:0, dx:0, dy:0, angle:0, scalex:1, scaley:nil, top:0, left:0, width:nil, height:nil, follow:nil, enabled:true }
    attach_count = 0
    options = {}
    new: (name, opt={}) =>
        options[name] = copy(default_opt)
        options[name].transform = love.math.newTransform()
        table.update(options[name], opt)
    @get = (name) -> assert(options[name], "Camera \'#{name}\' not found")
    @attach = (name) ->
        o = Camera.get name
        Draw.push()
        if o.enabled == false then return
        w, h = o.width or Game.width, o.height or Game.height
        if o 
            if o.follow then
                o.x = o.follow.x or o.x
                o.y = o.follow.y or o.y
            half_w, half_h = w/2, h/2
            Draw.crop(o.left, o.top, w, h)
            o.transform\reset!
            o.transform\translate half_w, half_h
            o.transform\scale o.scalex, o.scaley or o.scalex
            o.transform\rotate math.rad(o.angle)
            o.transform\translate(-floor(o.x - o.left + o.dx), -floor(o.y - o.top + o.dy))

            love.graphics.replaceTransform(o.transform)
    @detach = () ->
        Draw.pop()
    @use = (name, fn) ->
        Camera.attach(name)
        fn!
        Camera.detach()
    @count = () -> table.len(options)
    @useAll = (fn) ->
        for name, opt in pairs(options)
            Camera.use name, fn 

--MAP
export class Map extends GameObject
    options = {}
    images = {} -- { name: Image }
    quads = {} -- { hash: Quad }
    getObjInfo = (uuid, is_name) -> 
        if Game.config.scene and Game.config.scene.objects then 
            if is_name then
                for uuid, info in pairs(Game.config.scene.objects)
                    if info.name == uuid then
                        return info
            else
                return Game.config.scene.objects[uuid]
    @load = (name) ->
        data = love.filesystem.read(Game.res('map',name))
        assert(data,"Error loading map '#{name}'")
        new_map = Map!
        data = json.decode(data)
        layer_name = {}
        -- get layer names
        if not options.layer_order then options.layer_order = {}
        for info in *data.layers
            layer_name[info.uuid] = info.name
            table.insert(options.layer_order, info.name)
        -- place tiles
        for img_info in *data.images
            for l_uuid, coord_list in pairs(img_info.coords)
                l_name = layer_name[l_uuid]
                for c in *coord_list
                    new_map\addTile(img_info.path,c[1],c[2],c[3],c[4],c[5],c[6],l_name)
        -- spawn entities
        for obj_uuid, info in pairs(data.objects)
            obj_info = getObjInfo(obj_uuid)
            if obj_info
                for l_uuid, coord_list in pairs(info)
                    for c in *coord_list
                        new_map\_spawnEntity(obj_info.name,{
                            x:c[2], y:c[3], layer:layer_name[l_uuid]
                        })
        new_map.data = data
        return new_map
    @config = (opt) -> options = opt
    new: () =>
        super!
        @batches = {} -- { layer: { img_name: SpriteBatch } }
        @hbList = {}
        @addDrawable!
    addTile: (file,x,y,tx,ty,tw,th,layer) =>
        -- get image
        if not images[file] then images[file] = love.graphics.newImage(file)
        img = images[file]
        -- get spritebatch
        if not @batches[layer] then @batches[layer] = {}
        if not @batches[layer][file] then @batches[layer][file] = love.graphics.newSpriteBatch(img)
        sb = @batches[layer][file]
        -- get quad
        quad_hash = "#{tx},#{ty},#{tw},#{ty}"
        if not quads[quad_hash] then quads[quad_hash] = love.graphics.newQuad(tx,ty,tw,th,img\getWidth!,img\getHeight!)
        quad = quads[quad_hash]
        id = sb\add(quad,floor(x),floor(y),0)
        -- hitbox
        hb_name = if options.tile_hitbox then options.tile_hitbox[string.gsub(FS.basename(file), '.'..FS.extname(file), '')]
        body = nil
        if hb_name
            if options.use_physics
                hb_key = hb_name..'.'..tw..'.'..th
                if not Physics.getBodyConfig(hb_key)
                    Physics.body hb_key, {
                        shapes: {
                            {
                                type: 'rect'
                                width: tw
                                height: th
                                offx: tw/2
                                offy: th/2
                            }
                        }
                    }
                body = Physics.body hb_key
                body\setPosition(x,y)
            else 
                5
        tile_info = { :id, :body }
    _spawnEntity: (ent_name, opt) =>
        Game.spawn(ent_name, opt)
    spawnEntity: (ent_name, x, y, layer) =>
        obj_info = getObjInfo(ent_name, true)
        if obj_info then
            obj_info.x = x
            obj_info.y = y 
            obj_info.layer = layer
            @_spawnEntity ent_name, obj_info
    _draw: () => 
        for l_name in *options.layer_order
            if @batches[l_name]
                for f_name, batch in pairs(@batches[l_name])
                    Game.drawObject(@, batch)

--PHYSICS
export class Physics 
    world_config = {}
    body_config = {}
    joint_config = {}

    worlds = {}
    @custom_grav_helpers = {}
    @debug = false
    @update = (dt) ->
        for name, world in pairs(worlds)
            world\update dt
        for helper in *Physics.custom_grav_helpers
            helper\update dt

    @getWorldConfig = (name) -> world_config[name]
    @world = (name, opt) ->
        if type(name) == 'table'
            opt = name 
            name = '_default'
        if opt 
            world_config[name] = opt 
            table.defaults world_config[name], {
                gravity: 0
                gravity_direction: 90
                sleep: true
            }
        if not worlds[name]
            worlds[name] = love.physics.newWorld()
        w = worlds[name]
        c = world_config[name]
        -- set properties
        w\setGravity(Math.getXY(c.gravity_direction, c.gravity))
        w\setSleepingAllowed(c.sleep)
        return worlds[name]
        
    @getJointConfig = (name) -> joint_config[name]
    @joint = (name, opt) -> 
        if not worlds['_default'] then Physics.world('_default', {})
        if opt
            joint_config[name] = opt
            return

    @getBodyConfig = (name) -> body_config[name]
    @body = (name, opt) ->
        if not worlds['_default'] then Physics.world('_default', {})
        if opt
            body_config[name] = opt
            table.defaults body_config[name], {
                x: 0
                y: 0
                angularDamping: 0
                gravity: 0
                gravity_direction: 0
                type: 'static'
                fixedRotation: false
                bullet: false
                inertia: 0
                linearDamping: 0
                shapes: {}
            }
            return
        assert(body_config[name], "Physics config missing for '#{name}'")
        c = body_config[name]
        if not c.world then c.world = '_default'
        assert(worlds[c.world], "Physics world '#{c.world}' config missing (for body '#{name}')")
        -- create the body
        body = love.physics.newBody(worlds[c.world], c.x, c.y, c.type)
        helper = BodyHelper body
        -- set props
        props = {'angularDamping','fixedRotation','bullet','inertia','linearDamping'}
        for p in *props do body['set'..string.capitalize(p)](body,c[p])
        helper\setGravity c.gravity, c.gravity_direction
        shapes = {}
        for s in *c.shapes
            shape = nil
            table.defaults s, {
                density: 0
            }
            switch s.type
                when "rect"
                    table.defaults s, {
                        width: 1
                        height: 1
                        offx: 0
                        offy: 0
                        angle: 0
                    }
                    shape = love.physics.newRectangleShape(s.offx,s.offy,s.width,s.height,s.angle)
                when "circle"
                    table.defaults s, {
                        offx: 0
                        offy: 0
                        radius: 1
                    }
                    shape = love.physics.newCircleShape(s.offx,s.offy,s.radius)
                when "polygon"
                    table.defaults s, {
                        points: {}
                    }
                    assert(#s.points >= 6, "Physics polygon must have 3 or more vertices (for body '#{name}')")
                    shape = love.physics.newPolygonShape(s.points)
                when "chain"
                    table.defaults s, {
                        loop: false
                        points: {}
                    }
                    assert(#s.points >= 4, "Physics polygon must have 2 or more vertices (for body '#{name}')")
                    shape = love.physics.newChainShape(s.loop, s.points)
                when "edge"
                    table.defaults s, {
                        points: {}
                    }
                    assert(#s.points >= 4, "Physics polygon must have 2 or more vertices (for body '#{name}')")
                    shape = love.physics.newEdgeShape(unpack(s.points))
            if shape then 
                fix = love.physics.newFixture(body,shape,s.density)
                table.insert(shapes, shape)
        return body, shapes
    
    @setGravity = (body, angle, dist) ->
        helper = body\getUserData!
        helper\setGravity(angle, dist)

    @draw = (world_name='_default') ->
        if Physics.debug
            world = worlds[world_name]
            Draw.color(1,0,0,0.25)
            for _, body in pairs(world\getBodies!)
                for _, fixture in pairs(body\getFixtures!)
                    shape = fixture\getShape!
                    if shape\typeOf("CircleShape")
                        cx, cy = body\getWorldPoints shape\getPoint!
                        Draw.circle 'fill', cx, cy, shape\getRadius!
                    elseif shape\typeOf("PolygonShape")
                        Draw.poly 'fill', body\getWorldPoints(shape\getPoints!)
                    else 
                        Draw.line body\getWorldPoints shape\getPoints!
            Draw.color()

--PHYSICS.BODYHELPER
export class BodyHelper
    new: (body) =>
        @body = body
        @body\setUserData(helper)

        @gravx, @gravy = 0, 0
        @grav_added = false
    update: (dt) =>
        if @grav_added
            @body\applyForce(@gravx,@gravy)
    setGravity: (angle, dist) =>
        if dist > 0
            @gravx, @gravy = Math.getXY(angle, dist)
            @body\setGravityScale(0)
            if not @grav_added
                table.insert(Physics.custom_grav_helpers, @)
                @grav_added = true

--BLANKE
export Blanke = {
    load: () ->
        Game.load!

    update: (dt) ->
        if Game.options.update(dt) == true then return

        Physics.update dt

        len = #Game.updatables
        for o = 1, len
            obj = Game.updatables[o]
            if obj.destroyed or not obj.updatable
                Game.updatables[o] = nil
            else if obj._update then obj\_update(dt)
        
        Input.releaseCheck!
    
    draw: () ->
        actual_draw = () ->
            len = #Game.drawables
            for o = 1, len
                obj = Game.drawables[o]
                if not obj or obj.destroyed or not obj.drawable
                    Game.drawables[o] = nil
                else if obj.draw ~= false
                    if obj.draw then obj\draw(() -> if obj._draw then obj\_draw!)
                    else if obj._draw then obj\_draw!
            if Game.options.postDraw then Game.options.postDraw!
            Physics.draw!
       
        _draw = () ->
            if Camera.count! > 0
                Camera.useAll actual_draw
            else 
                actual_draw!

        if Game.options.draw   
            Game.options.draw _draw
        else 
            _draw!

    keypressed: (key, scancode, isrepeat) -> Input.press(key, {:scancode, :isrepeat})
    keyreleased: (key, scancode) -> Input.release(key, {:scancode})
    mousepressed: (x, y, button, istouch, presses) -> 
        Input.press('mouse', {:x, :y, :button, :istouch, :presses})
        Input.press('mouse'..tostring(button), {:x, :y, :button, :istouch, :presses})
    mousereleased: (x, y, button, istouch, presses) -> 
        Input.press('mouse', {:x, :y, :button, :istouch, :presses})
        Input.release('mouse'..tostring(button), {:x, :y, :button, :istouch, :presses})
}

love.load = () -> Blanke.load!
love.update = (dt) -> 
    Blanke.update dt
love.draw = () -> Blanke.draw!
love.keypressed = (key, scancode, isrepeat) -> Blanke.keypressed key, scancode, isrepeat
love.keyreleased = (key, scancode) -> Blanke.keyreleased key, scancode
love.mousepressed = (x, y, button, istouch, presses) -> Blanke.mousepressed x, y, button, istouch, presses
love.mousereleased = (x, y, button, istouch, presses) -> Blanke.mousereleased x, y, button, istouch, presses
-- from https://github.com/adnzzzzZ/STALKER-X
love.run = () ->
  if love.math then love.math.setRandomSeed(os.time())
  if love.load then love.load(arg)
  if love.timer then love.timer.step()

  dt = 0
  fixed_dt = 1/60
  accumulator = 0

  while true
    if love.event
      love.event.pump()
      for name, a, b, c, d, e, f in love.event.poll() do
        if name == "quit"
          if not love.quit or not love.quit()
            return a
        love.handlers[name](a, b, c, d, e, f)

    if love.timer
      love.timer.step()
      dt = love.timer.getDelta()

    accumulator += dt
    while accumulator >= fixed_dt do
      if love.update then love.update(fixed_dt)
      accumulator -= fixed_dt

    if love.graphics and love.graphics.isActive()
      love.graphics.clear(love.graphics.getBackgroundColor())
      love.graphics.origin()
      if love.draw then love.draw()
      love.graphics.present()

    if love.timer then love.timer.sleep(0.0001)

{ :Blanke, :Game, :Canvas, :Image, :Entity, :Input, :Draw, :Audio, :Effect, :Math, :Map, :Physics }