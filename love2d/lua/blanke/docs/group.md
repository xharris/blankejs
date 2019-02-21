
-- properties
obj[] children

-- instance methods
add(obj)
get(index)
remove(index)				-- index can be number or reference to object with a uuid
forEach(func)				-- calls func(index, obj) for each object. If true is returned, the loop will break early
call(func_name, [args])		-- calls obj[func_name](args) for each object
destroy()					-- destroys all objects in group
closest_point(x, y)			-- Entity only. get Entity closest to point
closest(entity)				-- Entity only. get Entity closest to entity
size()						-- number of children
