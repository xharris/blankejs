# BlankE tips
## Avoid sloppy code

1. try not to use global vars to communicate between objects
2. find object-oriented solutions
3. keep Net callbacks outside of class code

## Leave helpful comments for future you

It can be easy to navigate code that you're currently writing. Look at this snippet of code for example:
>```
>    tmr_field = Timer(2):after(function()
>        starting = false
>        local count = 6 + math.floor(2^(level/2)-1)
>        for i = 0, count do
>            asteroids:add(Asteroid())
>        end		
>        if not player and lives == 3 then player = Ship() end
>        level = level + 1
>        tmr_field = nil
>    end):start()
>```
Pretty simple, right? NOT REALLY!!

It's possible to look at this for a few minutes and eventually understand what's going on, but this could definitely be easier. After making this, a few comments here and there go a long way to making reading code easier on yourself in the future:
>```
>        # set up field for next round
>        tmr_field = Timer(2):after(function()
>			starting = false
>
>         # calculate number of asteroids to spawn based on current level
>			local count = 6 + math.floor(2^(level/2)-1)
>			for i = 0, count do
>				asteroids:add(Asteroid())
>			end		
>
>         # spawn the player if needed
>			if not player and lives == 3 then player = Ship() end
>			level = level + 1
>			tmr_field = nil
>		end):start()
>```
It's only a few vague comments, but it definitely helps for quick glances at this one section of a larger script.

## Avoid creating objects outside of functions

Both snippets below work, however the 2nd is better practice.

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

## Set destroyed objects to nil

Just destroying an object does not remove references to it

`my_entity:destroy()` the object will no longer be updated

`my_entity = nil` <font color="limegreen">GOOD</font> no longer any reference to it. It will eventually be freed up in memory
