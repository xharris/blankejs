## Entity - GameObject (updatable, drawable)

```
Entity("Player", {
  pos = { 50, 100 },
  prop1 = 'value1',
  prop2 = 4,
  added = function(ent)
    ent.prop1 = 'hi there'
    ent:bark()
  end,
  update = function(ent, dt)
    ent.pos[2] = ent.pos[2] + ent.prop2 * dt
  end,
  bark = function(self, arg1)
    ...
  end
})

Entity.spawn("Player", { custom_prop: 5 })

-- or --

Player = Entity("Player", { ... })

Player{custom_prop = 5}
```

The Entity class is actually just a convenience method for creating a `System`

# Construction Props

## visual

`images` { 'filename1', 'filename2', ... }

`animations` { 'animation_name1', ... }

`camera` can be a string of the Camera name or a list of Camera names

`effect` entity:setEffect <effect>

## collisions

`hitbox` values can be:
- true
- { left=-entity.alignx, top=-entity.aligny, right=0, bottom=0}

`reaction`  slide,

`reactions {}` optional list of { other_tag:'response' }. default reaction is `Hitbox.default_reaction ('slide')`

- reaction can be:

  - static : won't move from other hitbox collisions
  - cross : move throught other object
  - touch : stick to other object
  - slide : stop and slide across
  - bounce : bounces... (modifies vspeed and hspeed)

- reaction checking order:
  1. self.reaction
  2. other.reaction
  3. self:filter()
  4. Hitbox.default_reaction

`collision (self, info)` info = { <see below> }

- item

- other

- normal { x, y }

- move { x, y }

- touch { x, y }

- bounce { x, y }

`filter (self, other_entity)` return nil to ignore collision or a response string:

- `"touch"`

- `"cross"`

- `"slide"`

- `"bounce"`

## physics

`body` Physics.body <body>

`joint` Physics.joint <joint>

# Props

`x, y` 

`xprevious, yprevious` position from the last update frame

`hspeed, vspeed`

`gravity`

`gravity_direction = 90` 90=down, 0=right, 180=left, 270=up

`imageList, animList`

`animation` currently drawn animation

`anim_speed`

`anim_frame`

`map_tag` set if the Entity is given a tag in the Scene editor

# Methods

`setup(args, spawn_args)` called before anything is set up in Entity constructor

`spawn()`

`update(dt)`

`draw(default_draw_fn)`

**NOTE:** Draw operations are positioned relative to the entity. Calling `Draw.reset()` can change this to absolute positioning

`predraw()`

`postdraw()`

`ondestroy()`
