# named inputs

`Input.set(name, ...type)`

At the moment, __type__ can be a key code

# Other events

`Input.on(type, object, callback)`

or 

`Input.on(type, [object1, object2], callback)`

# Checking the state of the input

`Input(name)` returns { pressed, released }

Example:

>```
>Input.set("jump", "w", "up")
>...
>onUpdate: () => {
>   if (Input("jump").released)
>       player.jump();
>}
>```

## List of event types

```
click, pointercancel,
rightclick, rightdown, rightup, rightupoutside,
tap, touchcancel, touchend, touchendoutside, touchmove, touchstart,
mousedown, mousemove, mouseout, mouseover, mouseup, mouseupoutside,
pointerdown, pointermove, pointerout, pointerover, pointertap, pointerup, pointerupoutside
```

# Input key codes

[List of JS key values](https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/key/Key_Values)

There are a few shorthand key values built-in:

<table>
  <tr>
    <th>Shorthand&nbsp;&nbsp;&nbsp;&nbsp;</th>
    <th>Translation</th>
  </tr>
  <tr>
    <td>down</td>
    <td>ArrowDown</td>
  </tr>
  <tr>
    <td>left</td>
    <td>ArrowLeft</td>
  </tr>
  <tr>
    <td>right</td>
    <td>ArrowRight</td>
  </tr>
  <tr>
    <td>up</td>
    <td>ArrowUp</td>
  </tr>
  <tr>
    <td>space</td>
    <td>" "</td>
  </tr>
</table>