-- UTIL
table.update = (old_t, new_t, keys) -> 
    if keys == nil then
        for k, v in pairs new_t do old_t[k] = v
    else
        for k in *keys do if new_t[k] ~= nil then old_t[k] = new_t[k]

--GAME
_Game = {
    -- mutable
    res: '',
    load: () ->
    -- immutable
    objects: {},
    updatables: {},
    drawables: {},
    addObject: (name, _type, args, opt) ->
        -- store in object 'library' and update initial props
        if _Game.objects[_type][name] == nil then _Game.objects[_type][name] = {}
        table.update(_Game.objects[_type][name], args)
        -- extra options
        if opt.spawn_class then 
            _Game.spawn_class[name] = opt.spawn_class
    spawn_class: {},
    spawn: (name) ->
        if _Game.spawn_class[name] ~= nil

}
Game = (args) ->
    table.update(_Game, args, {'res','load'})
Game.spawn = (name) ->
    print name
    
--IMAGE

--ENTITY
class _Entity
    new: =>
Entity = (name, args) ->
    _Game.addObject(name, "Entity", args, { spawn_class: _Entity })

--BLANKE
BlankeLoad = () ->
    _Game.load!
BlankeUpdate = () ->
BlankeDraw = () ->

{ :BlankeLoad, :BlankeUpdate, :BlankeDraw, :Game, :Entity }