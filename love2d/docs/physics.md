# Class Methods

`world(name, [config])`

`joint(name, [config])` currently WIP

`body(name, [config])` returns body, shapes{}

`getWorldConfig(name), getJointConfig(name), getBodyConfig(name)`

`setGravity(body, angle, dist)`

`draw(world_name)`

## World config

* gravity
* gravity_direction = 90
* sleep = true

## Body config

* x, y
* angularDamping
* gravity
* gravity_direction
* type (static/dynamic)
* fixedRotation (bool)
* bullet (bool)
* inertia
* linearDamping
* shapes {list of Shapes} ex. {{type='rect', ....}, {}}
    * rect {width, height, offx, offy, angle}
    * circle {offx, offy, radius}
    * polygon {points[x, y, x, y, ...]}
    * chain {loop (t/f), points[x, y, x, y, ...]}
    * edge {points[x, y, x, y, ...]}

