## Draw

```
Draw.color('pink')
Draw.rect('fill', 50, 50, 100, 100)
Draw.color()
```
or
```
Draw{
    { 'color', 'pink' }
    { 'rect', 'fill', 50, 50, 100, 100 }
    { 'color' }
}
```

## Colors

```
red, pink, purple, deeppurple, 
indigo, blue, lightblue, cyan,
teal, green, lightgreen, lime,
yellow, amber, orange, deeporange, brown,
grey, gray, bluegray, white, white2, black, black2
```

# Class methods

`color(value)` value can be color string or `r g b a`

* `Draw.color(0,0,0,1)`
* `Draw.color('black')`
* `Draw.color({0,0,0,1})`

`getBlendMode(), setBlendMode(mode, [alphamode])`

`pointSize(size)`

`lineWidth(size)`

`crop(x,y,w,h)`

`reset([only])`

`push(), pop()` pop undoes all Draw settings after push was called (color, transforms)

`stack(fn)` wraps fn in push/pop

`clear`

`origin`

`discard`

## setting

`setLineWidth`

## drawing

__mode__: fill / line

`print (text, [x, y, r, sx, sy, ox, oy, kx, ky])` s=scale, o=offset, k=shear

`printf (text, x, y, limit, align, [r, sx, sy, ox, oy, kx, ky])` limit is horizontal width limit, align=center/left/right/justify

`line (x1, y1, x2, y2, ...)` can also be a table of lines

`points (x, y, ...)` can also be a table of points

`rect (mode, x, y, w, h, [rx, ry, segments])` rx/ry rounds corners

`polygon (mode, x, y, ...)` vertices can also be a table

`circle (mode, x, y, r, [segments])`

`ellipse (mode, x, y, rx, ry, [segments])`

`arc (mode, x, y, r, angle1, angle2, [segments])`