
-- class properties
num[4] color 						-- {r, g, b, a} used for ALL Draw operations
num[4] reset_color					-- {255, 255, 255, 255} (white) : used in resetColor()
num[4] 	red 
		pink
		purple
		indigo
		blue
		green
		yellow
		orange
		brown
		grey 
		black 
		white 
		black2 						-- lighter black
		white2 						-- eggshell white :)

-- class methods
setBackgroundColor(r, g, b, a)
setColor(r, g, b, a)				
randomColor(a)						-- random color with alpha a
resetColor()						-- color = reset_color	
push()
pop()
stack(fn) 							-- call push() --> fn() --> pop()

-- shapes
point(x, y, ...)					-- also takes in a table							
points								-- the same as point()
line(x1, y1, x2, y2)				
rect(mode, x, y, width, height)		-- mode = "line"/"fill"
circle(mode, x, y, radius)
polygon(mode, x1, y2, x2, y2, ...)
text(text, x, y, rotation, scale_x, scale_y, offset_x, offset_y)
textf(text, x, y, limit, align)		-- align = "left/right/center"
									-- rotation in radians
