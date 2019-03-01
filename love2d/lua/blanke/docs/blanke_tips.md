# BlankE tips
## Avoid sloppy code

1. try not to use global vars to communicate between objects
2. find object-oriented solutions
3. keep Net callbacks outside of class code

## Coding suggestions

1. Avoid creating objects outside of functions

<font color="red">NO</font>
```
main_camera = View()
function state0:enter()

end
```

<font color="limegreen">YES</font>
```
local main_camera = nil
function state0:enter()
    main_camera = View()
end
```

2. Just destroying an object does not remove references to it

`my_entity:destroy()` the object will no longer be updated

`my_entity = nil` <font color="limegreen">GOOD</font> no longer any reference to it. It will eventually be freed up in memory
