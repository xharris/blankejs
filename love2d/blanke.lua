table.update = function(old_t, new_t, keys)
  if keys == nil then
    for k, v in pairs(new_t) do
      old_t[k] = v
    end
  else
    for _index_0 = 1, #keys do
      local k = keys[_index_0]
      if new_t[k] ~= nil then
        old_t[k] = new_t[k]
      end
    end
  end
end
local _Game = {
  load = function() end
}
local Game
Game = function(args)
  return table.update(_Game, args, {
    'load'
  })
end
local Entity
Entity = function(name, args) end
local BlankeLoad
BlankeLoad = function()
  return _Game.load()
end
local BlankeUpdate
BlankeUpdate = function() end
local BlankeDraw
BlankeDraw = function() end
return {
  BlankeLoad = BlankeLoad,
  BlankeUpdate = BlankeUpdate,
  BlankeDraw = BlankeDraw,
  Game = Game,
  Entity = Entity
}
