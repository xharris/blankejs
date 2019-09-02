# Usage

`View(name)` returns a reference to the view

```
let my_view = View(ent_player);
my_view.follow(ent_player);

let my_drawing = new Draw();
my_view.add(my_drawing);
```

# Instance API

```
// Controls the rectangle view position and size
port_x, port_y
port_width, port_height

// Controls where the camera is looking
x, y
follow(obj)     // any object with an x and y value
add(obj)        // adds an object to be affected by the current view
remove(obj)     // opposite of add()
```