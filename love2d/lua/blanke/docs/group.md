A __Group__ can contain anything that can go in an array. This class is mostly for the easy handling of a lot of objects.

# Props

```
children[]
```

# Methods

```
add(obj)
get(index)
remove(index)				-- index can be number or reference to object with a uuid
call(func_name, [args])		-- calls obj[func_name](args) for each object
size()						-- number of children in the group
```
These methods work best when the Group is full of Entity objects:
```
sort(attribute, descending) -- sort objects by their attribute. sorts by ascending by default. sort('your_attr',true) will change it to descending
destroy()					-- destroys all objects in group
closest_point(x, y)			-- get Entity closest to point
closest(entity)				-- get Entity closest to entity
```
`forEach(func)` calls func(index, obj) for each object. If true is returned, the loop will break early.
>Example:
>```
>grp_rocks:forEach(function(r, rock)
>   if rock.size > 20 then
>       rock.pet = true
>   end
>end)
>```
