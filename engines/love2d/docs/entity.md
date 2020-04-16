## Entity - GameObject (updateable, drawable)

```
Entity("Player", {
    builtin_prop: 'value1'
    custom_prop: 4
    builtin_method: (arg1) =>
        ...
    custom_method: (arg1, arg2=5) =>
        ...
})

Game.spawn("Player", { custom_prop: 5 })

-- or --

Player = Entity("Player", { ... })

Player({custom_prop: 5})
```

# Construction Props

## visual

`images` { 'filename1', 'filename2', ... }

`animations` { 'animation_name1', ... }

`effect` entity:setEffect <effect>

## collisions

`hitbox` true -> Hitbox.add(entity)

`hitArea` { left=-entity.alignx, top=-entity.aligny, right=0, bottom=0}

`reaction {}` optional list of { other_tag:'response' }. default reaction is `Hitbox.default_reaction (slide)`

- reaction can be:

  - cross : move throught other object
  - touch : stick to other object
  - slide : stop and slide across
  - bounce : bounces...

- reaction checking order:
  1. self.reaction
  2. other.reaction
  3. self.filter
  4. Hitbox.default_reaction

`collision (self, info)` info = { <see below> }

- item

- other

- normal { x, y }

- move { x, y }

- touch { x, y }

`filter (self, item, other)` return nil to ignore collision or a response string:

- `"touch"`

- `"cross"`

- `"slide"`

- `"bounce"`

## physics

`body` Physics.body <body>

`joint` Physics.joint <joint>

# Props

`hspeed, vspeed`

`gravity`

`gravity_direction = 90` 90=down, 0=right, 180=left, 270=up

`imageList, animList`

`animation` currently drawn animation

`map_tag` set if the Entity is given a tag in the Scene editor

# Methods

`spawn()`

`update(dt)`

`draw()`

> **NOTE**: if draw() is used, width and height variables need to be set manually.

`predraw()`

`postdraw()`

`ondestroy()`
