# Set an input

## Anywhere

`Input.set('jump','up','w')`

Input.__set(name, ...)__ takes a name and any number of input constants 

## In BlankE options

```
BlankE.options = {
	inputs = {
		{"jump","up","w"}
	}
}
```

# Checking it

```
if Input("jump").released then
	player:jump()
end
```

## Input properties

```
can_repeat		-- default = true. if you set it to false, pressed will only be true once, every time the button is pressed (prevent repeated inputs)
pressed
released
```

# Controller

## Properties

`Input.controllers` contains info about all connected controllers
```
Input.controllers[id] = {
	id = number in controller order,
	name = "xbox, gamecube, etc"
	axisCount = num,
	canVibrate = bool
}
```

## Methods

`Input.setController(id)` all other methods get info about the controller set with this method.

>Ex: if **id** is 1, `Input("...")` and `Input.getAxis(...)` calls afterwards are for controller 1.

`Input.getAxis(i) ` get the i'th axis of the controller
```
Input.getVibration()
Input.setVibration(left, right, duration)	-- duration = -1 (infinite), nil/0 (stop)
```

>Example:
>```
>left_stick = { x=Input.getAxis(1), y=Input.getAxis(2) }
>right_stick = { x=Input.getAxis(3), y=Input.getAxis(4) }
>```