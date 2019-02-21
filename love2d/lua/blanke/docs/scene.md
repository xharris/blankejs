
Scene(scene_name)							-- initialize a scene as scene_name.json

-- instance methods
addEntity(object_name, class/instance, align)
	-- returns a list of entities created
	-- class: class to create instances of
	-- instance: already created instance that should be added to scene
	-- align: space-seperated keywords (center, top, bottom, left, right) Ex. "top left", "bottom", "center", "center right"
addTile(layer_name, info) 					-- info = { x, y, rect{x, y, w, h}, image }
addHitbox(name, ...)	 					-- create a hitbox for given object name(s)

getTiles(layer_name, image_name) 			-- returns [ { x, y, image (image name), crop{x, y, w, h} } ]
getObjects(name)							-- returns { layer_name:[ {x, y} ] }
getObjectInfo(name) 						-- returns { char, color, polygons:{ layer_name:[ {x, y} ] } }

translate(x, y)								-- move everything (tiles, hitboxes) by a given amount

draw(layer_name) 							-- layer_name (optional): draw only that layer
