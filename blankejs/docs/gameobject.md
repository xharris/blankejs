# GameObject

The following classes are considered a GameObject: __Draw, Canvas, Scene, Sprite, Entity, View, Map, Text__

# Properties/Methods

All GameObjects have the following properties and methods 

## Properties

`z` modifies the order in which objects are drawn. objects with a lower z index show up behind objects at a higher z.

`visible` true/false

`rect` changes the objects hitArea for Input interactions (mouse)

`effect` filter effects

* `effect = "my_effect"` enables a filter effect for that object
* `effect.my_effect` returns the Effect instance if it is enabled

Effect props/methods:
* any uniforms in the filter are a property of Effect (x,y,angle,amount,etc)
* `filter` PIXI.Filter instance
* `destroy()`

`particle` true/false. Only set true if a lot of this object will be drawn (thousands)

## Methods

`destroy()`