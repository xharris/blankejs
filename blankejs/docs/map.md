# I'M THE MAP

Maps are created by...

1. using `Add a map` in BlankE IDE (recommended)
2. creating a `new Map()` and manually adding things

# After using 'Add a Map'

Things to do in the scene editor:

* add image tiles
* add hitboxes using object placer
* add entity positions using object placer
  * if you have an entity named 'Player' and name a scene object 'Player', it will show the entity's currently set sprite. This will also make loading the map in-game easier later.

# Example usage

* Let's say we have an entity class named Player
* Let's say we also create a scene named "level1.map"
* An object is added and named 'Player'. One of those is placed in the map.
* Some tiles from 'ground.png/cement.png/spikes.png/lava.png' are also added
* We also add another object somewhere named 'InvisibleWall'


```
Scene("my_scene",{
    onStart: () {
        Map.config = {
            tile_hitbox: {
                'ground': ['ground','cement'],
                'death': ['spikes','lava']
            },
            entities: [Player],
            hitboxes: ['InvisibleWall']
        }
        var my_map = Map.load('level1.map')
    }
})
```

`tile_hitbox: { a: [b, c] }` this gives hitboxes to `b` and `c` image tiles with the tag `a`

`entities: [a, ...]` spawns an entity with the name `a` using the Entity class `a` (same name)

`hitboxes: [a, ...]` spawns a hitbox at objects with the name `a` and gives it the tag `a`

# Manually spawning

The things above can be spawned after loading the map using the following methods

`spawnEntity(entity_class, object_name)`

`spawnHitbox(object_name, [layer_name])`