-- TODO: , Canvas, Input, Draw, Physics, Sound, Effect, Camera, Map (uses Canvas)
import is_object, p from require "moon"

-- UTIL
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
uuid = require "uuid"
require "printr"

--GAME
class Game
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
        for lobj in *{...}
            love.graphics.draw lobj, gobj.x, gobj.y, math.rad(gobj.angle), gobj.scalex, gobj.scaley,
                gobj.offx, gobj.offy, gobj.shearx, gobj.sheary

    @isSpawnable: (name) -> objects[name] ~= nil

    @spawn: (name) ->
        obj_info = objects[name]
        if obj_info ~= nil and obj_info.spawn_class
            instance = obj_info.spawn_class(obj_info.args)
            return instance

--GAMEOBJECT
class GameObject 
    new: (args) =>
        @uuid = uuid()
        @x, @y, @z, @angle, @scalex, @scaley = 0, 0, 0, 0, 1, nil
        @offx, @offy, @shearx, @sheary = 0, 0, 0, 0
        @child_keys = {}
        if args then
            for k, v in pairs args
                if type(v) == "string" and Game.isSpawnable(v)
                    self[k] = Game.spawn(v)
                else if is_object(v)
                    table.insert(@child_keys, k)
                    @[k] = v!
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
    _draw: () => if @draw then @draw!
    _update: (dt) => if @update then @update dt
    destroy: () =>
        @destroyed = true
        for k in *@child_keys
            self[k]\destroy() 

--CANVAS
class Canvas extends GameObject
    new: (args) =>
        super!
        @angle = 0
        @auto_clear = true
        @canvas = love.graphics.newCanvas(Game.width, Game.height)
        @addDrawable!
    _draw: () => Game.drawObject(@, @canvas)
    drawTo: (obj) =>
        last_canvas = love.graphics.getCanvas()
        love.graphics.setCanvas(@canvas)
        if @auto_clear then Game.graphics.clear()
        if type(obj) == "function"
            obj()
        else if is_object(obj) and obj._draw
            obj\_draw()
        love.graphics.setCanvas(last_canvas)

--IMAGE
class Image extends GameObject
    new: (args) =>
        super!
        @image = love.graphics.newImage(Game.options.res..'/'..args.file)
        if @_spawn then @\_spawn()
        if @spawn then @\spawn()cs.newImage(Game.options.res..'/'..args.file)
        if args.drawable ~= false
            @addDrawable!
    _draw: () => Game.drawObject(@, @image)

--ENTITY
class _Entity extends GameObject
    new: (args) =>
        super args
        table.update(@, args)
        @imageList = {}

        if args.image then
            if type(args.image) == 'table' then
                @imageList = [Image {file: img, drawable: false} for img in *args.image]
            else 
                @imageList = {Image {file: args.image, drawable: false}}
        @addUpdatable!
        @addDrawable!
        if @spawn then @spawn!
    _update: (dt) =>
        if @update then @update(dt)
        for img in *@imageList
            img.x, img.y = @x, @y
    _draw: () =>
        for img in *@imageList
            img\_draw!

Entity = (name, args) ->
    Game.addObject(name, "Entity", args, _Entity)

--INPUT
class Input
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

    @press = (key, scancode, isrepeat) ->
        if input_to_name[key] 
            for name in *input_to_name[key]
                name_to_input[name][key] = true
                -- is input pressed now?
                combo = table.hasValue(options.combo, name)
                if (combo and table.every(name_to_input[name])) or (not combo and table.some(name_to_input[name]))
                        pressed[name] = true

    @release = (key, scancode, isrepeat) ->
        if input_to_name[key]
            for name in *input_to_name[key]
                name_to_input[name][key] = false
                -- is input released now?
                combo = table.hasValue(options.combo, name)
                if pressed[name] == true and (combo or not table.some(name_to_input[name]))
                        pressed[name] = false
                        released[name] = true
    
    @releaseCheck = () ->
        released = {}

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
        if Game.options.draw! == true then return

        len = #Game.drawables
        for o = 1, len
            obj = Game.drawables[o]
            if obj.destroyed or not obj.drawable
                Game.drawables[o] = nil
            
            if obj.draw ~= false
                if obj.draw then obj\draw!
                else if obj._draw then obj\_draw!

    keypressed: (key, scancode, isrepeat) -> Input.press(key, scancode, isrepeat)

    keyreleased: (key, scancode) -> Input.release(key, scancode)
}


{ :Blanke, :Game, :Canvas, :Image, :Entity, :Input }