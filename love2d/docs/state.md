## State

```
State('play',{
    enter = function()
        Map.load('level1')
    end,
    leave = function()
        print('bye now')
    end
})

Game{
    load = function()
        State.start('play')
    end
}
```

`State(name, callbacks)` 

callbacks: enter, update(dt), draw, leave

# Class Props

`curr_state` string / nil

# Class Methods

`start(name)`

`stop([name])`

`switch(name)` same as `State.stop() -> State.start(name)`