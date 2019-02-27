# Step-By-Step

1. Initialize the Effect

`local my_effect = Effect('static','chroma shift')`

2. Tweak the numbers

```
my_effect.static.amount = {2,0}
my_effect.chroma_shift.radius = 2
```

3. Draw the effect on top of something

```
function MyState:draw()
	my_effect:draw(function()
		my_image:draw()
		player:draw()
	end)
end
```

# Included effects & their options

**NOTE** any `color` properties are a vector4 with the value {r, g, b, a}. All values range from 0 to 1. Ex: red would be {1,0,0,1}

## chroma shift

* angle (degrees)
* radius

## outline

* color
* size

## static

* amount = {x, y}

## bloom

* samples (int)
* quality (float)

## zoom blur

* center = {x, y}
* strength (float)	

## warp sphere

* radius (float)
* strength (float)
* center = {x ,y}

## grayscale

* factor (float)

