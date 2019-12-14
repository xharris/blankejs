## Canvas - GameObject (drawable)

```
mycanvas = Canvas!
mycanvas:drawTo my_entity

mycanvas:draw!
```

# Constructor

`Canvas(w=Game.width, h=Game.height, settings)`

# Props

`width, height` read-only

`auto_clear=true` clear canvas before each `drawTo` call

`canvas` Love2D canvas instance

# Methods

`resize(w,h)`

`drawto(obj)`