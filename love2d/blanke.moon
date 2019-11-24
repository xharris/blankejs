-- TODO: Camera, Map (uses Canvas), Physics
import is_object, p, copy from require "moon"

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

--UTIL.string
string.contains = (str,q) -> (string.match(str, q) ~= nil)

uuid = require "uuid"
require "printr"

--GAME
export class Game
    @options = {
        res: '',
        filter: 'linear'
        load: () ->
        update: (dt) ->
        draw: () ->
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
        table.update(@@options, args, {'res','filter','load','draw','update'})
        return nil

    @load = () ->
        @width, @height = love.graphics.getDimensions()
        if type(Game.filter) == 'table'
            love.graphics.setDefaultFilter(unpack(Game.options.filter))
        else 
            love.graphics.setDefaultFilter(Game.options.filter, Game.options.filter)
        if @options.load then @options.load()

    @addObject = (name, _type, args, spawn_class) ->
        -- store in object 'library' and update initial props
        if objects[name] == nil then 
            objects[name] = {
                type: _type,
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
                love.graphics.draw lobj, props.x, props.y, math.rad(props.angle), props.scalex, props.scaley,
                    props.offx, props.offy, props.shearx, props.sheary
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
            instance = obj_info.spawn_class(obj_info.args, args)
            return instance

    @res: (_type, file) -> "#{Game.options.res}/#{file}"

    @setBackgroundColor: (...) -> love.graphics.setBackgroundColor(...)
    -- "#{Game.options.res}/#{_type}/#{file}"

--GAMEOBJECT
export class GameObject 
    new: (args) =>
        @uuid = uuid()
        @x, @y, @z, @angle, @scalex, @scaley = 0, 0, 0, 0, 1, nil
        @offx, @offy, @shearx, @sheary = 0, 0, 0, 0
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
    new: (args) =>
        super!
        @image = love.graphics.newImage(Game.res('image',args.file))
        if @_spawn then @\_spawn()
        if @spawn then @\spawn()cs.newImage(Game.res('image',args.file))
        if args.drawable ~= false
            @addDrawable!
    _draw: () => Game.drawObject(@, @image)

--ENTITY
export class _Entity extends GameObject
    new: (args, spawn_args) =>
        super args
        table.update(@, args)
        @imageList = {}

        if args.image then
            if type(args.image) == 'table' then
                @imageList = [Image {file: img, drawable: false} for img in *args.image]
            else 
                @imageList = {Image {file: args.image, drawable: false}}
        for img in *@imageList 
            img.parent = @

        if args.effect then
            if type(args.effect) == 'table'
                @setEffect unpack(args.effect)
            else 
                @setEffect args.effect

        @addUpdatable!
        @addDrawable!
        if @spawn then 
            if spawn_args then @spawn unpack(spawn_args)
            else @spawn!
    _update: (dt) =>
        if @update then @update(dt)
        for img in *@imageList
            img.x, img.y = @x, @y
    _draw: () =>
        for img in *@imageList
            img\draw!

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
    new: (instructions) =>
        for instr in *instructions
            name, args = instr[1], table.slice(instr,2)
            Draw[name](unpack(args))
    @color = (...) ->
        if #{...} == 0 then
            love.graphics.setColor(1,1,1,1)
        else 
            love.graphics.setColor(...)

    @getBlendMode = () -> love.graphics.getBlendMode()
    @setBlendMode = (...) -> love.graphics.setBlendMode(...)
    @reset = (only) ->
        if only == 'color' or not only
            Draw.color(1,1,1,1)
            -- Draw.setLineWidth
            --if only == 'transform' or not only
            -- Draw.origin()
        if (only == 'crop' or not only) and Draw.crop_used
            -- Draw.crop_used = false
            love.graphics.setStencilTest()
    @push = () -> love.graphics.push('all')
    @pop = () -> 
        Draw.reset('crop')
        love.graphics.pop()
    @stack = (fn) ->
        Draw.push()
        fn!
        Draw.pop()

draw_functions = {'arc','circle','clear','discard','ellipse','line','points','polygon','rectangle'}
draw_aliases = {
    polygon: 'poly',
    rectangle: 'rect'
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

--BLANKE
Blanke = {
    load: () ->
        Game.load!

    update: (dt) ->
        if Game.options.update(dt) == true then return

        len = #Game.updatables
        for o = 1, len
            obj = Game.updatables[o]
            if obj.destroyed or not obj.updatable
                Game.updatables[o] = nil
            else if obj._update then obj\_update(dt)
        
        Input.releaseCheck!
    
    draw: () ->
        _draw = () ->
            len = #Game.drawables
            for o = 1, len
                obj = Game.drawables[o]
                if not obj or obj.destroyed or not obj.drawable
                    Game.drawables[o] = nil
                
                else if obj.draw ~= false
                    if obj.draw then obj\draw(() -> if obj._draw then obj\_draw!)
                    else if obj._draw then obj\_draw!

        if Game.options.draw then Game.options.draw(_draw)
        else _draw!

    keypressed: (key, scancode, isrepeat) -> Input.press(key, {:scancode, :isrepeat})
    keyreleased: (key, scancode) -> Input.release(key, {:scancode})
    mousepressed: (x, y, button, istouch, presses) -> Input.press('mouse', {:x, :y, :button, :istouch, :presses})
    mousereleased: (x, y, button, istouch, presses) -> Input.release('mouse', {:x, :y, :button, :istouch, :presses})
}


{ :Blanke, :Game, :Canvas, :Image, :Entity, :Input, :Draw, :Audio, :Effect }