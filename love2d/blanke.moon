-- UTIL
table.update = (old_t, new_t, keys) -> 
    if keys == nil then
        for k, v in pairs new_t do old_t[k] = v
    else
        for k in *keys do if new_t[k] ~= nil then old_t[k] = new_t[k]
uuid = require "uuid"
require "printr"

--GAME
class Game
    @options = {
        res: '',
        load: () ->
    }
    objects = {}
    @updatables = {}
    @drawables = {}

    new: (args) =>
        table.update(@@options, args, {'res','load'})
        return nil

    @load = () ->
        if @@options.load then @@options.load()

    @addObject = (name, _type, args, spawn_class) ->
        -- store in object 'library' and update initial props
        if objects[name] == nil then 
            objects[name] = {
                type: _type,
                :args
                :spawn_class
            }

    @spawn: (name) ->
        obj_info = objects[name]
        if obj_info ~= nil and obj_info.spawn_class
            instance = obj_info.spawn_class(obj_info.args)
            return instance

--GAMEOBJECT
class GameObject 
    new: () =>
        @uuid = uuid()
        @x, @y, @z = 0, 0, 0
        if @_spawn then @\_spawn()
        if @spawn then @\spawn()
    addUpdatable: () =>
        @updatable = true
        table.insert(Game.updatables, @)
    addDrawable: () =>
        @drawable = true
        table.insert(Game.drawables, @)
        table.sort(Game.drawables, (a, b) -> a.z < b.z)
    destroy: () =>
        @destroyed = true

--IMAGE
class _Image extends GameObject
    new: (args) =>
        super!
        @image = love.graphics.newImage(Game.options.res..'/'..args.file)
        @addDrawable!
    _draw: () =>
        love.graphics.draw(@image, @x, @y)

--ENTITY
class _Entity extends GameObject
    new: (args) =>
        super!
        table.update(@, args)
        @imageList = {}

        if args.image then
            if type(args.image) == 'table' then
                @imageList = [_Image {file: img} for img in *args.image]
            else 
                @imageList = {_Image {file: args.image}}
        @addUpdatable!
        @addDrawable!
    _update: (dt) =>
        if @update then @update(dt)
        for img in *@imageList
            img.x, img.y = @x, @y

Entity = (name, args) ->
    Game.addObject(name, "Entity", args, _Entity)

--BLANKE
BlankeLoad = () ->
    Game.load!

BlankeUpdate = (dt) ->
    len = #Game.updatables
    for o = 1, len
        obj = Game.updatables[o]
        if obj.destroyed
            Game.updatables[o] = nil
        else if obj._update then obj\_update(dt)

BlankeDraw = () ->
    len = #Game.drawables
    for o = 1, len
        obj = Game.drawables[o]
        if obj.destroyed
            Game.drawables[o] = nil
        else if obj._draw then obj\_draw()

{ :BlankeLoad, :BlankeUpdate, :BlankeDraw, :Game, :Entity }