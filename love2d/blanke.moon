-- UTIL
table.update = (old_t, new_t, keys) -> 
    if keys == nil then
        for k, v in pairs new_t do old_t[k] = v
    else
        for k in *keys do if new_t[k] ~= nil then old_t[k] = new_t[k]

--GAME
_Game = {
    load: () ->
}
Game = (args) ->
    table.update(_Game, args, {'load'})

--ENTITY
Entity = (name, args) ->

--BLANKE
BlankeLoad = () ->
    _Game.load!
BlankeUpdate = () ->
BlankeDraw = () ->

{ :BlankeLoad, :BlankeUpdate, :BlankeDraw, :Game, :Entity }