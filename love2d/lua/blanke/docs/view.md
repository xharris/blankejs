View
	extension of HUMP camera
]]

-- instance properties
bool disabled
Entity follow_entity		-- entity for view to follow

num follow_x, follow_y 		-- better to use moveToPosition()
num offset_x, offset_y		
str motion_type 			-- none, linear, smooth
num speed 					-- = 1
num max_distance			-- = 0

num angle 					-- default: 0 degrees
num rot_speed				-- angle rotation speed
str rot_type				-- none, damped
num scale_x, scale_y		-- = 1, stretch/squeeze view
num zoom_speed				-- = .5
str zoom_type				-- none, damped

num port_x, port_y			-- uses love2d Scissor to crop view
num port_width, port_height -- uses love2d Scissor to crop view
bool noclip					-- HUMP attach option. maybe it determines whether things outside view are visible
num top 					-- [readonly] y coordinate of top edge
num bottom					-- [readonly] y coordinate of bottom edge

num shake_x, shake_y		-- = 0
num shake_intensity			-- = 7
num shake_falloff 			-- = 2.5
str shake_type 				-- smooth, rigid

bool draggable				-- drag the camera around using mouse_position
Input drag_input			-- input that toggles whether camera is being dragged

-- methods
position()					-- returns camera position
follow(Entity)				-- follows an Entity
moveTo(Entity) 				-- camera smoothly/linearly moves to entity position
snapTo(Entity)				-- camera immediately moves to entity
moveToPosition(x,y)			
snapToPosition(x,y)
rotateTo(angle)
zoom(scale_x, [scale_y, callback])	-- if only scale_x is supplied, scale_y is set to scale_x, callback runs after zoom animation finishes
mousePosition()				-- get mouse position relative to world
shake(x, [y])				-- sets shake_x
squeezeH(amt)				-- similar to scale_x except view is centered
attach()					-- set the camera for drawing
detach()					-- unset camera for drawing
draw(draw_function)			-- wraps draw_function in attach/detach methods
