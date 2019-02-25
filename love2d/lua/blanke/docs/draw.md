# **Color** arg

For any function using the arg **color**, the following values types are acceptable:

* rgba table `{r, g, b, [a]}`. Preferred range is 0-1, but 0-255 is also usable.
* hex string `#fff`/`fff`/`#ffffff`/`ffffff`
* premade color (See 'COLORS' below)

# Props

```
color = {r, g, b, a}				-- used for ALL Draw operations
reset_color = {1,1,1,1}				-- used for resetColor()
font 								-- current Font object in use
```

## Colors
```
red, pink, purple, indigo, blue, green, yellow, orange, brown, grey, gray, black, white,
black2 (lighter black),
white2 (eggshell white :)
```
<br />

# Methods

## Color
```
setBackgroundColor(color)
setColor(color)		
setAlpha(a)		
randomColor(a)				-- random color with alpha a
invertColor(color)
```

## Transform
```
translate(x, y)
scale(x, y)
shear(x, y)
rotate(deg)

```

## Shapes -- Actually drawing stuff
```
point(x, y, ...)			-- also takes in a table	
line(x1, y1, x2, y2)				
rect(mode, x, y, width, height)
circle(mode, x, y, radius)
polygon(mode, x1, y2, x2, y2, ...)
text(text, x, y, options)
```
**mode** = 'line' or 'fill'

text **options** = {

* `max_x` maximum width of text block. Also affects where text is drawn when modifying 'align'.
* `align` 'left'/'center'/'right'/'justify'
* `angle` degrees
* `scale_x`, `scale_y`
* `offset_x`, `offset_y`
* `shear_x`, `shear_y`

}

## Other 
```
setPointSize(s)	-- affects size of Draw.point()
setLineWidth(s)	-- affects size of line/rect/circle/polygon
```
`grid(rows, columns, h_spacing, v_spacing, fn)`

Calls `fn()` for each cell in an imaginary grid. Good for drawing a chessboard or anything grid related.

>Example:
>```
>Draw.translate(game_width/2, game_height/2)
>Draw.setColor("blue")
>Draw.grid(3, 3, 50, 50, function(x, y, row, column)
>		Draw.circle("line", x, y, 3)
>		Draw.text("("..row..", "..column..")", x, y)
>end)
>```

`reset([x])` **x** can be 'color'/'transform'. No value resets everything.

`push()` save the current drawing state (colors, transformations)

`pop()` restores the drawing state before `push()` was used

`stack(fn)`	calls `push()` --> `fn()` --> `pop()`