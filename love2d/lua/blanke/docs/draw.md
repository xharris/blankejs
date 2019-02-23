# Color arg

For any function using the arg **color**, the following values types are acceptable:

* rgba table `{r, g, b, [a]}`. Preferred range is 0-1, but 0-255 is also usable.
* hex string `#fff`/`fff`/`#ffffff`/`ffffff`
* premade color (See 'COLORS' below)

# Props

```
color = {r, g, b, a}				-- used for ALL Draw operations
reset_color = {1,1,1,1}				-- used for resetColor()
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
text(text, x, y, degrees, scale_x, scale_y, offset_x, offset_y)
textf(text, x, y, limit, align)		-- align = "left/right/center"
```
**mode** = 'line' or 'fill'

## Other 
```
setPointSize(s)	-- affects size of Draw.point()
setLineWidth(s)	-- affects size of line/rect/circle/polygon
```
`grid(rows, columns, h_spacing, v_spacing, fn)`

Calls `fn()` for each cell in an imaginary grid. Good for drawing a chessboard or anything grid related.

>Example:
>```
Draw.setColor("blue")
Draw.grid(3, 3, 5, 5, function(x, y, row, column)
	Draw.circle("line", x, y)
	Draw.text("row: "..row.." col: "..column)
end)
```

`reset([x])` **x** can be 'color'/'transform'. No value resets everything.

`push()` save the current drawing state (colors, transformations)

`pop()` restores the drawing state before `push()` was used

`stack(fn)`	calls `push()` --> `fn()` --> `pop()`