## Camera

`Camera "playerview"`

or...

```
Camera("playerview", {
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

`x, y, width, height`

`angle` degrees

`scalex, scaley`

`follow` object with x and y properties

`crop` = false. Determines whether everything outside of a camera will be visible

`enabled`

`auto_use` = true. Determines whether `Camera.use(<name>, drawGame)` will automatically be called in the main draw loop 

# Class Methods

`get(name)` get camera options

`attach(name)`

`detach()`

`use(name, fn)` attach(name) -> fn -> detach

