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

## chroma shift

* angle (degrees)
* radius

## outline

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

