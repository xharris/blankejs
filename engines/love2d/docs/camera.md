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

`enabled`

# Class Methods

`get(name)` get camera options

`attach(name)`

`detach()`

`use(name, fn)` attach(name) -> fn -> detach

