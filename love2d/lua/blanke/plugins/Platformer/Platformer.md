BlankE.loadPlugin(name)

## Methods

`(Entity):addPlatforming([left, top, width, height])`
-- creates hitboxes: main_box, head_box, feet_box

`(Entity):platformerCollide{tag, tag_contains, [wall, ceiling, floor, all]}`

* __tag__: exact tag match to collide with

* __tag_contains__: if the tag contains the given string

* __wall__, __ceiling__, __floor__: collision callbacks. return false to ignore collision

* __all__: called if colliding with ANYTHING
