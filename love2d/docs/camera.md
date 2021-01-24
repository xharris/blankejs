## Camera

`local cam = Camera("playerview")`

or...

```
local cam = Camera("playerview", {
    angle = 45
})
```

and then...

```
Entity("Player", {
    camera = "playerview"
    ...
```

# Options

`viewx, viewy, width, height` viewport position/dimensions

`angle` radians

`scalex, scaley`

`follow` object with a _pos_ property (Ex. `pos = {0,0}`)

`crop` = false. Determines whether everything outside of a camera will be visible

`enabled`

`auto_use` = true. Determines whether `Camera.use(<name>, drawGame)` will automatically be called in the main draw loop 

# Class Methods

`get(name)` get camera options

`attach(name)`

`detach()`

`use(name, fn)` attach(name) -> fn -> detach

