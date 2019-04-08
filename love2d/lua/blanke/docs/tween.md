# What is Tween?

**Tween** is used to slowly (or quickly) move a variable from one value to another. If you want to zoom the camera instead of snapping between 1 and 2, you can ease between the two values at a certain speed.

>Example
>```
>if Input("action").released then
>    Tween(View("main"), {zoom=2}, 2):play()
>end
>```

# Initialization

`Tween(var, value, [duration, tween_type, onFinish])`

* **var** the starting value OR an object
* **value** target object properties or value
* **duration** seconds
* **tween_type** linear, quad [in, out, in/out], circ in
* **onFinish** called when the tween finishes

# Props

```
onFinish       
```

# Methods

```
setStartValue(value)    
setEndValue(value)
play()
```

## add or modify tween functions
```
addFunction(name, fn)       -- fn(a, b, d, dt) where a=start, b=end, d=lerp %, dt=delta time
setFunction(name)
```