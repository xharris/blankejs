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
```

# Construction Props

## visual

`images` { 'filename1', 'filename2', ... }

`animations` { 'animation_name1', ... }

`effect` entity:setEffect <effect>

## collisions

`hitbox` true -> Hitbox.add(entity)

`hitArea` { left=-entity.alignx, top=-entity.aligny, right=0, bottom=0}

`collision (self, info)` info = { <see below> }

* item

* other

* normal { x, y }

* move { x, y }

* touch { x, y }

`collFilter (self, item, other)` return nil to ignore collision or a response string:

* `"touch"`

* `"cross"`

* `"slide"`

* `"bounce"`

`collList {}` list of { other_tag:response }. default response is `Hitbox.default_coll_response (slide)`

## physics

`body` Physics.body <body>

`joint` Physics.join <joint>

# Props

`hspeed, vspeed`

`gravity`

`gravity_direction = 90` 90=down, 0=right, 180=left, 270=up

`imageList, animList`

`animation` currently drawn animation

# Methods

`spawn()`

`update(dt)`

`draw()`

> __NOTE__: if draw() is used, width and height variables need to be set manually

`onDestroy()`
