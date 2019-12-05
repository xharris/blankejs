## Draw

```
Draw.color('pink')
Draw.rect('fill', 50, 50, 100, 100)
Draw.color()
```
or
```
Draw {
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

`print`

`printf`

`line`

`points`

`rect`

`polygon`

`circle`

`ellipse`

`arc`