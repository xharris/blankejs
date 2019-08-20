# Usage

`View(name)` returns a reference to the view

```
let my_view = View("player")
my_view.add(scene1)
my_view.follow(ent_player)
```

# Instance API

```
// Controls the rectangle view position and size
port_x, port_y
port_width, port_height

// Controls where the camera is looking
x, y
follow(obj)     // any object with an x and y value
```