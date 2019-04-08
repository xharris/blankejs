# Props
```
State.background_color      -- only affects this state
```

# Methods
```
State.current()                     -- gets the name of the current state
State.switch(name)                  -- name can be string or State object. If empty, it will just clear the current state.
State.transition(name, animation, args...)  -- similar as State.switch
```

## Transition animations

* circle-in
* circle-out
* wipe-up
* wipe-down
* clockwise
* counter-clockwise
* fade
    * arg1: color

# Callbacks
```
(state):load()				-- run only first time state is loaded
(state):enter(previous)		-- run every time state is loaded. previous = prev state
(state):leave()				-- run every time state is left for another.
(state):update(dt)
(state):draw()
```

>Example:
>```
>function myState:enter()
>   ...
>end
>```

