# Creation

`local rpt_name = Repeater(texture, [options])`

* texture can be an Image / Canvas / Entity / Sprite
* options is an optional table containing Particle Properties listed below

# Props

Repeater Properties

```
rate            -- particle is emitted every x seconds
emit_count		-- how many particles to emit at once by default
count           -- readonly. how many particles are currently alive
particles[]     -- list of current particles. modifying values in this is not recommended
```

Particle Properties

```
x
y
duration
direction       -- degrees. 0 = right, 90 = down
speed
offset_x
offset_y
r               -- red
g               -- green
b               -- blue
a               -- alpha
spr_frame
spr_speed
```

## Random range

If a property is set to a table value, every new particle created will be given a random value within the given range.

>Example: `rpt_dots.direction = {45, 135}` will create particles with the property _direction_ set to a random value between 45 and 135.

## Tweening

Some variables have a second end-value that ends with a '2'. Each new particle will start out with the first property and end with the property2 value.

>Example: `rpt_dots.direction = 45; rpt_dots.direction2 = 90`
>
>This will set each new particles direction to 45 and tween it over time so that it's direction ends up at 90 by the time the particle disappears.

>Example: `rpt_dots.direction = {45,45,'quad in'}; rpt_dots.direction2 = 90`
>
>Same as previous example, except 'quad in' is the tween function used for this property

The following variables can be tweened: `direction, speed, offset_x, offset_y, r, g, b, a`

# Methods

```
setTexture(texture)     -- texture can be Image / Canvas / Entity
emit([x])               -- creates x particles. if rate > 0, this is called automatically
```