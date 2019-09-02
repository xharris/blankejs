[//]: # (Name: Platformer.js)

# Purpose

Adds simple hitboxes to an Entity that can be used in a platformer.

# Example Usage

```
class MyEntity extends Entity {
    init () {
        this.addSprite("walk","player_walk");
        this.sprite_align = "center"

        this.addPlatforming({
            width: this.sprite_width - 4,
            height: this.sprite_height,
            tag: 'ground',
            on: {
                head: (other, info) => {
                    console.log("ow my head");
                }
            }
        })
    }
}
```

# "Docs"

`this.addPlatforming(options)` the plugin adds this method to all Entities. `options` is optional.

## options

`width` default: sprite_width

`height` default: sprite_height

`tag` tag that hitboxes will collide with.

`margin` default: 3. how much space is between the head/feet hitboxes and the left/right sides of the entity. recommended not to alter this value.

`on` object to set callbacks for each hitbox. addPlatforming creates 3 hitboxes (head/feet/body). The corresponding callback is run when a collision happens.

Example:
```
    on: {
        head: (other, info) => {

        },
        feet: (other, info) => {

        },
        body: (other, info) => {

        }
    }
```