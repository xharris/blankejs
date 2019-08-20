# Drawing something

```
let my_drawing = new Draw(
    ['fill',Draw.white],
    ['rect',0,0,50,50],
    ['fill']
);
```

OR 

```
let my_drawing = new Draw();
my_drawing.draw(
    ['fill',Draw.white],
    ['rect',0,0,50,50],
    ['fill']
)
```

# Possible instructions

cx/cy = center x/y ⬩ 
cp = control point ⬩ 
r = radius (0 = right, 180 = left) ⬩ 
angle = degrees

## styling

`fill` color, alpha (both beginFill/endFill) 

`texture` image_name, [color, alpha] (both beginTextureFill/endFill)

`entity` instance, [color, alpha]

> __NOTE__: Be careful when using __texture/entity__ if auto_clear is set to 0. Drawing many textures using the Draw class could lead to using up a lot of memory since the Draw class still calculates it's own hitbox. Alternatively use Canvas.

`lineStyle` width, color, alpha, alignment (0 = inner, 0.5 = middle, 1 = outer)

`lineTextureStyle` width, texture, color, alpha, Matrix, alignment

## path/movement

`moveTo` x, y

`lineTo` x, y

`bezierCurve` cp_x1, cp_y1, cp_x2, cp_y2, end_x, end_y

`quadCurve` cp_x, cp_y, end_x, end_y

`closePath`

## shapes

`rect` x, y, w, h

`circle` x, y, r

`polygon` x1, y1, x2, y2, ...

`roundRect` x, y, w, h, r

`ellipse` x, y, w, h

`star` x, y, points (>1), r, inner_r, angle

`arc` cx, cy, r, start_angle, end_angle, counterclockwise

`arcTo` x1, y1, x2, y2, r
