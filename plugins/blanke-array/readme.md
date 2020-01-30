[//]: # (Name: Blanke Array)

```
local myarray = Array(1,2,3) -- or Array({1,2,3})
myarray[2] = 6
print(myarray[2]) -- 6
print(myarray) -- 1,2,6
```

# Instance Property

`length`

`table` returns the lua table

# Instance Methods

`push(val1, val2, ...)`

`pop()` removes and returns last value in array

`remove(at, [amt])`

`copy()` returns clone as a new Array

`includes(val)` true/false

`fill(val, [start, end])` start/end are optional indexes

`indexOf(val)`

`join(sep)`

`forEach(fn)` fn(val, index). return true to break loop early

`sort(...)` uses lua's table.sort(...)

`concat(val1, val2, ...)` value can be any value or 1D array

`some(fn)` returns true if fn(val, index) returns true for at least one value

`every(fn)` returns true if fn(val, index) returns true for all values

`shuffle()` Fisher-Yates shuffle

`sort([fn])` uses lua's table.sort

`random()` returns random value from table

## These functions return self reference (for chaining)

`map(fn)` fn(val, index) should return new val

`filter(fn)` fn(val, index) should return true if the value should be kept

`reverse()`

