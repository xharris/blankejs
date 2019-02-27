__What is an Entity?__ a game object that can have hitboxes/collisions and sprite animations.

# Props
```
num x, y position
num xprevious, yprevious	-- location during last update loop
num xstart, ystart			-- location when object is first created. not always 0,0
```

## Movement
```
num direction			-- in degrees
num friction
num gravity
num gravity_direction	-- in degrees. 0 = right, 90 = down, default = 90
num hspeed, vspeed
num speed 				-- best used with 'direction'
```

## Animation
```
str sprite_index
num sprite_width, sprite_height
num sprite_angle					-- in degrees
num sprite_xscale, sprite_yscale	-- 1 = normal scaling, -1 = flip
num sprite_xoffset, sprite_yoffset
num sprite_xshear, sprite_yshear
num sprite_color = {1,1,1,1}		-- blend color for sprite. {r,g,b,a}
num sprite_alpha = 255		
num sprite_speed = 1		
num sprite_frame
```

## Debugging
`bool show_debug`

# Methods
```	
distancePoint(x ,y)				-- entity origin distance from point
distance(other_entity)
moveTowardsPoint(x, y, speed)	-- sets direction and speed vars
containsPoint(x, y)				-- checks if a point is inside the sprite (not hitboxes)
```

## Animation/Drawing
```
addAnimation{					
	name = ""
	image = ""
	frames = {...}
	frame_size = {width, height}
	speed = 0.1
	offset = {x, y}
}
```

* **name** name of animation for this entity (Ex. 'bob_stand', 'bob_walk')
* **image** image asset name
* **frames** {'1-2', 1} means columns 1-2 and row 1
* **frame_size** {32,32} means each frame is 32 by 32
* **speed** smaller = faster

`drawSprite(sprite_index)` calls default draw function for given animation name

## Collision
```
addShape{					
	name = "",
	shape = "",
	dimensions = {...}
}
```

* **name** name of hitbox (Ex. 'main', 'left_arm')
* **shape** rectangle, circle, polygon, point
* **dimensions** relative to entity x/y
	* rectangle: `{left, top, width, height}`
	* circle: `{x, y, radius}`

`setMainShape(name)`
`removeShape(name)` disables a shape. it is still in the shapes table however and will be replaced using addShape(same_name)

## Debugging
`debugSprite()` green: call during `draw()`
`debugCollision()` red: shows hitboxes	

{} net_sync_vars					-- variables to be synced by the Net library
