## Input

```
Input({
    left = { "left", "a" }
    right = { "right", "d" }
    jump = { "up", "w" }
    action = { 'space', 'mouse1' }
}, { no_repeat = { 'jump' }, combo = { 'action' } })

update: (dt) =>
    if Input.pressed('left')
        -- do something
```

# Configure inputs

`Input inputs, options`

* `inputs` ex. { name: { 'input1', ... } }
    * Keyboard 
    * Mouse `mouse, mouse1, mouse2, ...` 'mouse' is any mouse button
    * Coming soon: touch, joystick, gamepad
* `options`
    * `norepeat` keys that only trigger once on press
    * `combo` only triggered when all inputs are pressed

# Class Methods

`Input.addInput(name, inputs, options)`

`Input.pressed(name)` returns extra Love2D info as a table

`Input.released(name)`