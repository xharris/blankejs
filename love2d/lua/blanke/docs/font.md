# Ways to set the font

1. `Draw.setFont("myfont")`

2. `Draw.setFont{name="console", size=16}`

3. ```
   local fnt_whatever = Font{name="console", size=16}
   Draw.setFont(fnt_whatever)
   ```

# Options

## Regular Font

`name` asset name

`size` size

## Bitmap Font

`image` asset name 

`characters` string of characters in the image from left to right

## Other options

`align` "left"/"right","center"

`limit` wraps characters after given pixels. 

## Tips

* to draw in the center of the screen use 
```
local fnt_center = Font{align = "left", limit = game_width}
Draw.setFont(fnt_center)
Draw.text("this is centered", 0, game_height/2 - fnt_center:getHeight()/2)
```