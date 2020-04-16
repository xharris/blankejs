## Image - GameObject (updatable)

# Constructor

`Image(options)`

`options`

* `draw=false` if true then `img:addDrawable()`
* `animation` animation name

# Class Methods

`info(name)`

`animation(file, animations, global_options)`

* `animations[]`
    * `name` animation name
    * `rows, cols`
    * `offx, offy`
    * `frames` ex. { '1-3', 5, 6 }
    * `duration` ms duration of each frame
    * `durations{}` ms duration of certain frames ex. { '2': 1.5 }
    * `speed=1` higher makes animation faster

# Props

`frame_index` 

`frame_count`