# BlankE.options." ... "

`state` automatically set if you don't change this value (It's highly recommended you set this to state that you want to load first). If this is set to `nil`, no state will load.

`resolution` 1 - 7 / {800, 600}

`filter` linear, nearest

`scale_mode` scale, stretch, fit, center

`inputs` list of Input object parameters

`input.no_repeat` see 'Input'

`debug.play_record` play last recorded game

`debug.record` record this playthrough

`debug.log` draw Debug.log to screen


	_options = {
		resolution = Window.resolution,
		plugins={},
		filter="linear",
		scale_mode=Window.scale_mode,
		auto_aspect_ratio=true,
		state='',
		inputs={},

## Example 

```
BlankE.options = {
	state = "PlayState",
	resolution = 2, 	// uses 2nd resolution preset
	filter = 'nearest',
	inputs = {
		{'move_left','a','left'},
		{'move_right','d','right'},
		{'jump','space','up','w'}
	},
	input = {
		no_repeat={"jump"}
	},
	debug = {
		log = true
	}
}
```