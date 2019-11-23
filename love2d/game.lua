local Entity, Game, Canvas, Input, Draw, Audio
do
  local _obj_0 = require("blanke")
  Entity, Game, Canvas, Input, Draw, Audio = _obj_0.Entity, _obj_0.Game, _obj_0.Canvas, _obj_0.Input, _obj_0.Draw, _obj_0.Audio
end
local is_object, p
do
  local _obj_0 = require("moon")
  is_object, p = _obj_0.is_object, _obj_0.p
end
Game({
  res = 'data',
  filter = 'nearest',
  load = function()
    Game.spawn("Player")
    return Audio.play('manyfire')
  end
})
Audio('fire.ogg', {
  name = 'manyfire',
  looping = true,
  volume = 0.2
})
Input({
  left = {
    "left",
    "a"
  },
  right = {
    "right",
    "d"
  },
  up = {
    "up",
    "w"
  }
}, {
  no_repeat = {
    "up"
  }
})
Entity("Player", {
  image = 'soldier.png',
  testdraw = {
    {
      color = {
        1,
        0,
        0,
        0.5
      }
    },
    {
      line = {
        0,
        0,
        Game.width / 2,
        Game.height / 2
      }
    }
  },
  update = function(self, dt)
    local hspeed = 20
    if Input.pressed('right') then
      self.x = self.x + (hspeed * dt)
    end
    if Input.pressed('left') then
      self.x = self.x - (hspeed * dt)
    end
  end,
  draw = function(self, d)
    Draw({
      {
        'color',
        1,
        0,
        0
      },
      {
        'line',
        self.x,
        self.y,
        Game.width / 2,
        Game.height / 2
      },
      {
        'color'
      }
    })
    return d()
  end
})
return Entity("FakePlayer", {
  image = 'soldier.png',
  spawn = function(self)
    self.x = Game.width / 2
  end
})
