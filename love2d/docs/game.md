# Game options

```
Game{
    res                 = "assets",     -- assets folder
    scripts             = {},           -- scripts to require()
    filter              = "linear",     -- or "nearest"
    vysnc               = "on",         -- or "off"/"adaptive"
    auto_require        = true,         -- automatically requires scripts in same directory as main.lua
    background_color    = nil,          -- rgb table or color string
    fps                 = 60,
    round_pixels        = false,
    effect              = "",            -- Effect string

    load = function()
    update = function(dt)
    draw = function(d) -- d is default draw function
    
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

# The Big Three

There are 3 main structures that everything in BlankE is based off of:

* `class` [lua-clasp](https://github.com/evolbug/lua-clasp)
* `callable` a regular table that can be called like a function

    > ```
    > Game = callable{
    >     __call = function(t, arg1)
    >         -- function call code
    >         -- t is a reference to the table
    >     end,
    >     width = 0,
    >     height = 0,
    >     doSomething = function(arg1)
    > 
    >     end
    > }
    >
    > Game('myarg1')
    > Game.width = 500
    > Game.doSomething('alsomyarg1')
    > ```
* `table`
  * This is just a regular lua table