# Props
## Initialization
```
options = {
	resolution = 3,
	plugins = {},
	filter = "linear",
	scale_mode = 'scale',
	auto_aspect_ratio = true,
	state = nil,
	inputs = {},			
	debug = {
		play_record=false,		
		record=false,			
		log=false					
	}
}
```
## Debugging
`draw_debug = false`
## Drawing window
Gives the exact location of where the game is drawn in relation to the window
```
left = 0
top = 0
right = 0
bottom = 0
```

## Methods
`BlankE.init([options])`

* **options** overrides BlankE.options

`drawOutsideWindow()` can be overriden to make custom drawings outside the game frame