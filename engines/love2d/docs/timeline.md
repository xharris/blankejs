## Timeline (Updatable, Drawable)

```
local tline_intro = Timeline({
    -- for 1 second, move to the right
    {1000,
        fn = function()
            my_entity.hspeed = 20
            my_entity.vspeed = 0
        end
    },
    -- for 1 second, move upwards
    {1000,
        fn = function()
            my_entity.hspeed = 0
            my_entity.vspeed = -20
        end
    },
    -- watch the entity animate until a keypress
    {'wait',
        fn = function()
            my_entity.animation = "dance"
        end,
        update = function(tline, dt)
            if Input.pressed('continue') then
                tline:step()
            end
        end
    },
    -- finally, draw some text
    {'wait', name = 'final',
        fn = function()
            my_entity.animation = 'stand'
        end,
        draw = function()
            Draw.printf("welcome to the game!", Game.width/2, 0, "center")
        end
    }
})

tline_intro:play()
```

`Timeline(steps[], spawn_args{})`

# Instance methods

`pause() / resume()`

`play([name])` start from the beginning or from the given step `name`

`step([name])` move to next timeline step or to a given step `name`

`reset()` start from the beginning

# Step properties

```
{
    1000,                   -- duration of this step (milliseconds)
                            -- 'wait' is infinite duration until step() is called
                            -- the default duration is 0
                            
    name = '',              -- optional label for step
    fn = fn(tline),         -- called once when step starts
    update = fn(tline, dt)  -- called during update loop
    draw = fn(tline)        -- called during draw loop
}
```
