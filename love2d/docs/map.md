## Map - GameObject (drawable)

```
Map.config{
    tile_hitbox = { img_ground='ground' }
}
mymap = Map.load('level2.map')
```

# Class Methods

`config(options)`
* `layer_order[]` back to front
* `use_physics=false` determines whether box2D physics or normals Hitbox class will be used
* `tile_hitbox{}` { image_name: 'hitbox_tag' } 

# Methods

`addTile(img_filename, x, y, tx, ty, tw, th, [layer])`
* `x, y` tile position
* `tx, ty, tw, th` tile crop info
* `layer` optional layer name

`spawnEntity(object_name, x, y, [layer])` object_name is from map file