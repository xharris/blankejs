-- instance properties
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

-- methods
draw()
								-- w/h argument limits size of tiling. TODO: use scissor?
tileX([w])						-- draw function that tiles image horizontally
tileY([h])						-- draw function that tiles image vertically
tile([w, h])					-- draw function that tiles image horiz and vert

setWidth(width)
setHeight(height)
setSize(width, height)
combine(other_image)			-- paste 'other_image' onto current image
Image[] chop(width, height)		-- chops image into smaller images of width/height
Image crop(x, y, w, h)			-- obvious
