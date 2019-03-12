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

## Input checking properties

```
pressed
released
```