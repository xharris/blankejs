# What is View?

**View** is a camera that can follow a point or an Entity.

>Example
>```
>function myState:enter()
>	View("main").follow(my_entity)
>end
>
>function myState:draw()
>	View("main").draw(function()
>		my_entity:draw()
>	end)
>end
>```

Views can also be stored in variables

`local my_view = View("main")`

# Props

```
x, y
top, left, bottom, right	-- readonly
mouse_x, mouse_y			-- mouse position inside view
port_width, port_height
follow_entity
offset_x, offset_y
```

## drawing 

```
angle						-- degrees
scale_x
scale_y
zoom						-- affects scale_x and scale_y when changed
```

## movement

```
move_type					-- default = 'snap'
lock_rect = [0,0,w,h]
```

## shaking

```
shake_speed
shake_duration
```

# Methods

```
follow(entity)
moveTo(x, y)
shake(x, y)
draw(fn)
```