## Path - GameObject (updatable, drawable)

```
local paths = map:getPaths("path_node", "layer1")
local player = Game.spawn("player")
paths[1]:go(player, { speed=50, target={tag='end'} })
```

# Class Properties

`debug`

# Instance Properties

`color` debug color

`node{}` { hash:{ x, y, tag } }

`edge{}` { hash:{ a=node_hash, b=node_hash, tag } }

`matrix{}` { node_a={ node_b=edge_hash, ... } }

`debug`

# Instance Methods

`addNode(opt) -> node_hash` opt = { x, y, tag }

`getNode(opt) -> node_hash` opt = { x, y, tag }

`addEdge(opt) -> edge_hash` opt = { a=node_hash, b=node_hash }

`getEdge(opt) -> edge_hash` opt = { a=node_hash, b=node_hash }

`go(obj, opt)`
  * `obj` with x and y values
  * `opt{}` { speed=1, target={ x, y, tag }, [start]={ x, y, tag}, [onFinish]=function }

`pause(obj)`

`resume(obj)`

`stop(obj) -> next_node, onFinish` stops pathing completely. will not trigger onFinish
