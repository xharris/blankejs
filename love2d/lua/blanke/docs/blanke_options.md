# BlankE.options." ... "
`filter` linear, nearest

`scale_mode` scale, stretch, fit, center

`inputs` list of Input object parameters

`input.no_repeat` see 'Input'

`debug.play_record` play last recorded game

`debug.record` record this playthrough

`debug.log` draw Debug.log to screen

## Example 

```
BlankE.options = {
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