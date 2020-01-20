# Game options

```
Game{
    filter = "linear"/"nearest"
    res = "assets" -- assets folder
    scripts = {} -- scripts to require()
    load = function()
    update = function(dt)
    draw = function(d) -- d is default draw function
    effect = ""-- Effect string
    auto_require = true -- automatically requires scripts in same directory as main.lua
    backgroundColor = nil -- rgb table or color string
    window_flags = {}
    plugins = {} -- list of plugin ids
}
```

window_flags can be found on the [Love2D wiki](https://love2d.org/wiki/love.window.setMode)

# Ways to load a plugin

1. ```
    Game{
        plugins = {'xhh-tween'}
    }
    ```

2. `require "xhh-tween"`

Usually depends on the plugin. Try checking the plugin's docs!