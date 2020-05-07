## Input

```
Input.set({
    left = { "left", "a", "gp.dpleft" },
    right = { "right", "d", "gp.dpright" },
    jump = { "up", "w", "gp.a" },
    action = { 'space', 'mouse1' },
}, { no_repeat = { 'jump' }, combo = { 'action' } })

update: (dt) =>
    if Input.pressed('left')
        -- do something
```

* `Input(name)` returns info about the info

# Configure inputs

`Input.set(inputs, options)`

* `inputs` ex. { name: { 'input1', ... } }
    * Keyboard 
    * Mouse `mouse, mouse1, mouse2, ...` 'mouse' is any mouse button
    * Gamepad `gp.?`
      * d-pad: `dpleft, dpright, dpup, dpdown`
      * buttons: `a, b, x, y, back, start, guide`
      * shoulder: `leftshoulder, rightshoulder`
    * Coming soon: touch
* `options`
    * `norepeat` keys that only trigger once on press
    * `combo` only triggered when all inputs are pressed

## Gamepad Axis

* You can only get axis information using `Input(axis)`
  * sticks: `leftx, lefty, rightx, righty`
  * triggers: `triggerleft, triggerright`

Eg `Input('leftx')` will return a table with the keys:
* joystick: [JoystickObject](https://love2d.org/wiki/Joystick)
* value: number in range [-1, 1]

# Class Methods

`Input.addInput(name, inputs, options)`

`Input.pressed(name)` returns extra Love2D info as a table

`Input.released(name)`
