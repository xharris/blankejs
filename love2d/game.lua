local Entity, Game, Canvas, Input, Draw, Audio, Effect
do
  local _obj_0 = require("blanke")
  Entity, Game, Canvas, Input, Draw, Audio, Effect = _obj_0.Entity, _obj_0.Game, _obj_0.Canvas, _obj_0.Input, _obj_0.Draw, _obj_0.Audio, _obj_0.Effect
end
local is_object, p
do
  local _obj_0 = require("moon")
  is_object, p = _obj_0.is_object, _obj_0.p
end
local eff
Game({
  res = 'data',
  filter = 'nearest',
  load = function()
    Game.setBackgroundColor(1, 1, 1, 1)
    Game.spawn("Player")
    eff = Effect("chroma shift")
  end,
  draw = function(d)
    eff:set("chroma shift", "radius", (love.mouse.getX() / Game.width) * 20)
    return eff:draw(function()
      Draw.color(0, 1, 0)
      Draw.rect('fill', 50, 50, 200, 200)
      Draw.color()
      return d()
    end)
  end
})
Audio('fire.ogg', {
  looping = false,
  volume = 0.2
})
Effect.new("chroma shift", {
  vars = {
    angle = 0,
    radius = 2,
    direction = {
      0,
      0
    }
  },
  blend = {
    "replace",
    "alphamultiply"
  },
  effect = "\n        pixel = pixel * vec4(\n        Texel(texture, texCoord - direction).r,\n        Texel(texture, texCoord).g,\n        Texel(texture, texCoord + direction).b,\n        1.0);\n    ",
  draw = function(vars, applyShader)
    local angle, radius
    angle, radius = vars.angle, vars.radius
    local dx = (math.cos(math.rad(angle)) * radius) / Game.width
    local dy = (math.sin(math.rad(angle)) * radius) / Game.height
    vars.direction = {
      dx,
      dy
    }
  end
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
  },
  action = {
    'space'
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
    if Input.released('action') then
      return Audio.stop('fire.ogg')
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
