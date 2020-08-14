## Input

```
Input.set({
    left = { "left", "a", "gp.dpleft" },
    right = { "right", "d", "gp.dpright" },
    jump = { "up", "w", "gp.a" },
    action = { 'space', 'mouse1' },
}, { no_repeat = { 'jump' }, combo = { 'action' }, group = 'player1' })

update = function(dt)
    Input.group = 'player1' -- only necessary if there are multiple groups
    if Input.pressed('left')
        -- do something
```

* `Input(name)` returns info about the info

# Configure inputs

`Input.set(inputs, options)`

* `inputs` ex. { name: { 'input1', ... } }
    * Keyboard [KeyConstant](https://love2d.org/wiki/KeyConstant)
    * Mouse `mouse, mouse1, mouse2, ...` 'mouse' is any mouse button
    * Gamepad `gp.?`
      * d-pad: `dpleft, dpright, dpup, dpdown`
      * buttons: `a, b, x, y, back, start, guide`
      * shoulder: `leftshoulder, rightshoulder`
    * Coming soon: touch
* `options`
    * `norepeat` keys that only trigger once on press
    * `combo` only triggered when all inputs are pressed
    * `group` add these inputs to the given group. can be any value.

## Gamepad Axis

* You can only get axis information using `Input(axis)`
  * sticks: `leftx, lefty, rightx, righty`
  * triggers: `triggerleft, triggerright`

Eg `Input('leftx')` will return a table with the keys:
* joystick: [JoystickObject](https://love2d.org/wiki/Joystick)
* value: number in range [-1, 1]

# Class Properties

`group` set this to a value to only check inputs of that group. Set `Input.group = nil` to get inputs that aren't in a group.

# Class Methods

`Input.addInput(name, inputs, options)`

`Input.pressed(name)` returns extra Love2D info as a table

`Input.released(name)`
