## Window

# Class properties

`width, height` read-only. Gives window size, which is not always the same as game size.

`os` 'mac'/'win'/'linux'. Current os the game is being played on.

`aspect_ratio` {x,y}. Usually 4:3, 5:4, 16:10, 16:9

# Class methods

`vsync(v)` 1 = on, 0 = off, -1 = adaptive 

`setSize(s, [flags])` s = [1,7] sets game size to a given pre-determined size based on aspect ratio
> `Window.setSize(3)` -- this might give you a window size of { 800, 600 }. depends on the aspect_ratio

`setExactSize(w, h, [flags])`

`fullscreen([v], [type])` sets fullscreen state. Returns current fullscreen state if no value is given
* type can be:
  * 'desktop' borderless fullscreen windowed
  * 'exclusive' regular fullscreen
  
`toggleFullscreen()`
