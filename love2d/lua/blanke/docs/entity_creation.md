# BlankE automatic creation

**Search** `Add an entity` and enter a name.

The script that is created can be renamed without affecting the Entity's name.

# Manual Step-By-Step
## 1. Create the script
**Search** `Add a script`
This can be renamed to whatever, but it is best if the name is the same as your Entity class name. For example: An entity class named "Player" would go in `Player.lua`.

## 2. Create the class
`BlankE.addEntity("Player")`
This is the preferred shorthand for `BlankE.addClassType("Player","Entity")`

## 3. Add the callbacks
```
function Player:init()
    -- ...
end

function Player:update(dt)
    -- ...
end

function Player:draw()
    -- ...
end
```