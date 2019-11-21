-- UTIL
table.update = (old_t, new_t, keys) -> 
    if keys == nil then
        for k, v in pairs new_t do old_t[k] = v
    else
        for k in *keys do if new_t[k] ~= nil then old_t[k] = new_t[k]

--GAME
class Game
    options = {
        res: '',
        load: () ->
    }
    objects = {}
    @updatables = {}
    @drawables = {}

    new: (args) =>
        table.update(options, args, {'res','load'})
        return nil

    @load = () ->
        if options.load then options.load()

    @addObject = (name, _type, args, opt) ->
        -- store in object 'library' and update initial props
        if objects[name] == nil then 
            objects[name] = {
                type: _type,
                args: args
            }
        table.update(objects[name], opt)

    @spawn: (name) ->
        obj_info = objects[name]
        if obj_info ~= nil and obj_info.spawn_class
            instance = obj_info.spawn_class(obj_info.args)
            if obj_info.updatable then table.insert(@@updatables, instance)
            if obj_info.drawables then 
                table.insert(@@drawables, instance)
                table.sort(@@drawables, (a, b) -> a.z < b.z)
        
            return instance

--IMAGE

--ENTITY
class _Entity
    new: (args) =>
        @z = 0
        table.update(@, args)
Entity = (name, args) ->
    Game.addObject(name, "Entity", args, { 
        spawn_class: _Entity
        updatable: true,
        drawable: true
    })

--BLANKE
BlankeLoad = () ->
    Game.load!
BlankeUpdate = (dt) ->
    for obj in *Game.updatables
        if obj.update then obj\update(dt)
BlankeDraw = () ->

{ :BlankeLoad, :BlankeUpdate, :BlankeDraw, :Game, :Entity }