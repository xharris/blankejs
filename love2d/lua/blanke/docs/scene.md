# Creating a scene

1. Use scene editor

Search for `Add a scene` and go nuts

2. Initalize in the code

`local sc_test = Scene('scene0')` where scene0 is whatever your scene is named

# Props

These are properties that can be set on the class. They affect all Scenes that are created.

```
tile_hitboxes[]
hitboxes[]
entities[]
```

You can fill these lists with image/object names and they will be automatically created using addTile, addTileHitbox, and addHitbox when a scene is used.

```
dont_draw[]
draw_order[]
```

These affect how elements in a scene are drawn. 

By default every entity added to the scene is drawn when draw() is called. Adding an object name to **dont_draw** prevents this. 

**draw_order** affects the order in which things are drawn automatically. This can contain both image names and object names.

>Example:
>```
>Scene.tile_hitboxes = {'ground'}
>Scene.entities = {{"player",Player},{"boss",Boss1}}
>Scene.dont_draw = {"player"}
>Scene.draw_order = {"ground","Boss1","Player"}
>```
>In the example, ground is given a hitbox, player and boss entities are added, and player is not drawn when draw() is called. The draw order is set to ground > Boss1 > Player.

# Methods

```
getLayer(name)		-- returns layer info
sortLayers()		-- should be called if depth variable is changed for a layer
draw([layer_name]) 	-- draws all layers (tiles, entities) or just layer_name
translate(x, y)		-- moves all entities, hitboxes, and tiles by x/y

getObjects(name)	-- returns object list
getObjectNames()	-- returns a list of object names
getObjectInfo(name)	-- returns object info

getTiles(layer_name, img_name)	-- returns {{x,y,img_name,crop{x, y, w, h}}, ...}
getEntities(object_name)		-- gets list of entites created with object_name

addTile(layer_name, info)	-- info = { x, y, rect{x, y, w, h}, image_name}
addTileHitbox(img_name)		-- adds a hitbox to all tiles with given image name
addHitbox(object_name)
```

`addEntity(object_name, class/instance, align)`

* **name** of the object from the scene editor
* Entity **class** or an already created **instance**
* **align**: "x y" / "x" / "y" where...
	* x values: center, left, right
	* y values: center, top, bottom

`chain(next_scene, object_end, object_start)` adds a scene to the end of the current scene. The scenes will be joined together by object_end and object_start.

* object_end - placed in the current scene
* object_start - placed in the next scene