BlankE.loadPlugin(name)

--Platformer
(Entity):addPlatforming(left, top, width, height) 						
-- creates hitboxes: main_box, head_box, feet_box

(Entity):platformerCollide{tag, tag_contains, wall, ceiling, floor, all}				
-- tag: exact tag match to collide with
-- tag_contains: if the tag contains the given string
-- [wall, ceiling, floor]: collision callbacks. return false to ignore collision
-- [all]: called if colliding with ANYTHING
