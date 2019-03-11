# Props
```
str name 					-- path used to create image
num x, y 					-- position for draw()
num angle 					-- degrees
num xscale, yscale 			-- = 1
							-- xscale = -1 to flip horizontally
							-- yscale = -1 to flip vertically
num xoffset, yoffset 		
num color{r,g,b}			-- = 255, blend color
num alpha 					-- = 255, opacity
num orig_width 				-- original width of image (before scaling)
num orig_height
num width, height 			-- width/height including scaling
```

# Methods
## drawing the image
`draw([x, y])` __x__ and __y__ override image.x and image.y instance vars

Tiling - draws the image repeatedly over a given distance
```
tileX([w])						-- draw function that tiles image horizontally
tileY([h])						-- draw function that tiles image vertically
tile([w, h])					-- draw function that tiles image horiz and vert
```

```
setWidth(width)
setHeight(height)
setSize(width, height)
combine(other_image)			-- paste 'other_image' onto current image
Group chop(width, height)		-- chops image into smaller images of width/height and puts them in a group
Image crop(x, y, w, h)			-- obvious
Image frame(f, frame_w, frame_h, spacing_x, spacing_y) -- same as crop but with spritesheet-like parameters
```
