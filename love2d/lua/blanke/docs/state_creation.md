# BlankE automatic creation

**Search** `Add an state` and enter a name.

The script that is created can be renamed without affecting the State's name.

# Manual Step-By-Step
## 1. Create the script
**Search** `Add a script`
This can be renamed to whatever, but it is best if the name is the same as your State name. For example: An state named "MenuState" would go in `MenuState.lua`.

## 2. Create the class
`BlankE.addState("MenuState")`
This is the preferred shorthand for `BlankE.addClassType("MenuState","State")`

## 3. Add the callbacks
```
function MenuState:enter()
    -- ...
end

function MenuState:update(dt)
    -- ...
end

function MenuState:draw()
    -- ...
end
```