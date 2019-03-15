# First, what is it?

More commonly known as a particle system, a **Repeater** creates many of the same image and adds properties or motion to that image copy. Good for stuff like fire, smoke, or confetti.

# How to use it

1. Create the Repeater

``` 
local img_dot, rpt_dots

function State1:enter()
    img_dot = Image("dot")
    rpt_dots = Repeater(img_dot, {
        x = game_width / 2,
        y = game_height / 2,
        direction = {45, 135},
        speed = {3,6}
    })
    rpt_dots.rate = 0.1
end
```

2. Draw the Repeater

```
function State1:draw()
    rpt_dots:draw()
end
```

That's all that needed for a basic Repeater.