[//]: # (Name: Blanke Tween)

Uses [tween.lua by kikito](https://github.com/kikito/tween.lua)

# Usage

`Tween(duration, subject, target, [easing, onFinish])`

* duration - seconds (unless Tween.ms == true)
* subject - object whose values will be tweened
* target - object that describes the desired result
* easing - string or Tween.easing.<ease_function>. default is linear
* onFinish - callback function when tween ends

Ex.

```
require "xhh-tween"

my_tween = Tween(5, player, { hspeed = 0 })
my_tween.mod = 2.0 -- makes tween go twice as fast.
```

# Instance properties/methods

`mod = 1` changes speed of tween (larger = faster)

`completed = set(v)` sets time of Tween. returns whether it is finished

`pause()`

`resume()`

# Easing functions

* linear
* quad, cubic, quart, quint, expo, sine, circle
* back (slightly back then forward)
* bounce
* elastic

## Variants

Every ease function (except linear) has 4 variants: __in, out, inOut, outIn__

Use it like this: `cubic` -> `inOutCubic`

# Custom easting function

```
custom_fn = function(x1, y1, x2, y2)
    curve = love.math.newBezierCurve(0,0,x1,y1,x2,y2,1,1)
    return function(t, b, c, d) return c * curve:evaluate(t/d) + b end
end
Tween(4, myobj, { y = 4 }, custom_fn(0.2, 0.5, 0.2, 0.4))
```

* __t__ ime - current time (moving towards duration)
* __b__ egin - initial value
* __c__ hange - ending target value
* __d__ uration - total time of tween