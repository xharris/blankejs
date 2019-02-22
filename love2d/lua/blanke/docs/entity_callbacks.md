## Most useful
```
update(dt)
draw()

postUpdate(dt)  -- after all hitbox and motion logic is calculated
preDraw()
postDraw()
```

## Note about overriding draw()
The draw method calls `preDraw`, `drawSprite`, and `postDraw`. If you override this method, these functions need to be called manually in `draw()` if they are needed.