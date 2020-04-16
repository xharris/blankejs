## GameObject

A parent class for some classes

# Props

`x, y, z` z: larger = closer, smaller = farther away

`angle` degrees

`scalex, scaley, scale`

`width, height` read-only

`offx, offy, shearx, sheary`

`align` left/right top/bottom center

`blendmode` { mode, alphamode }

`parent` read-only

`camera` Camera.get(<camera>).follow = gameobject

`destroyed` true/false

# Methods

`addUpdatable()` adds object to update list 

`addDrawable()` add object to draw list

`remUpdatable(), remDrawable()` removes object from list

`setEffect(name,...)` adds shader effects with given names

`destroy()`