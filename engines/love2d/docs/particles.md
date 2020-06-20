## Particles - GameObject (updatable, drawable)

```
local part = Particles{
  source = "bunny.bmp",
  rate = 5,
  speed = { 10, 20 }
}

part.x = 10
part.y = 20
part:lifetime(20)
part:speed(12, 18)

part:source(my_entity)
```

## instance properties

`x, y` position of instance (moves all particles). also, look at `position(x,y)`.

## instance methods

`source(obj)` Canvas, Image, Entity

`frame(n)` for Image/Entity only. 0 = animate normally, 1+ = stay on a certain frame

`stop()` set the rate to 0

`emit(n)` send out a burst of n particles

## instance methods (particles)

`position(x, y)` position of the emitter

`max(n)` buffer size, maximum amount of particles in system

`color({r,g,b,a}, {r,g,b,a}, ...)` will use these colors over the particles lifetime. max 8 colors.

`direction(rad)`

`area(distribution, dx, dy, [angle], [relative])` where particles spawn
* distribution
  * "uniform" / "normal"
  * "ellipse": uniform in ellipse
  * "borderellipse": edge of ellipse
  * "borderrectangle": edge of rectangle
  * "none": disable area
* relative: particles will spawn relative to center of instance

`rate(t)` t = particles per second

`lifetime(sec_min, [sec_max])` particle lifespan

`linear_accel(xmin, ymin, [xmax], [ymax])`

`linear_damp(min, [max])` constant deceleration

`offset(x, y)` offset position particles rotate around. by default they rotate around the source's `align` offset.

`rad_accel(min, [max])` radial acceleration

`relative(enable)` whether particle angle/rotation is relative to velocity.

`rotation(min, [max])` angle in radians

`size_vary(amt)` amt = [0, 1] size variation between start and end 

`sizes(a, b, c, ...)` 1 = normal size. particles will interpolate between each size over it's lifetime. min 1 size, max 8 sizes.

`speed(min, [max])` linear speed

`spin(min, [max])` radians per second

`spin_var(amt)` amt = [0, 1] spin variation between start and end

`spread(amt)` amt is in radians

`tan_accel(min, [max])` acceleration perpendicular to particle's direction

`insert(mode)` "top" / "bottom" / "random" where to insert new particles in the list