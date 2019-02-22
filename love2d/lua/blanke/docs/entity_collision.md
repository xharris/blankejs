# Step-By-Step
## 1. Add hitbox in init()
```
function MyEntity:init()
    self:addShape("main", "rectangle", {0,0,32,32})
end
```
> `self:setMainShape("main")` does not need to be called in this case, since there is only one hitbox. The main shape is always set to the first hitbox added to the Entity.

## 2. Check for a collision in update()
```
function MyEntity:update(dt)
    self.onCollision["main"] = function(other, sep_vector)

    end
end
```
> `function(other, sep_vector)`

* **other** The other hitbox this is colliding with. Contains properties such as `parent`, which is the Entity the other hitbox belongs to.
* **sep_vector** The vector created that explains how far each hitbox will move in the next step if they do not stop.

## 3. Do something during the collisino
```
function MyEntity:update(dt)
    self.onCollision["main"] = function(other, sep_vector)
        if other.parent.classname == "ground" then
            self:collisionStopY()
        end
    end
end
```
These 3 functions can only be called during a collision. They affect the entity's movement.
```
fn collisionStop()
fn collisionStopX()
fn collisionStopY()
```

# Platformer example

**NOTE:** There is a platformer plugin that can do a lot of this for you, and more.
```
function entity0:init()
	self.gravity = 30
	self.can_jump = true
	self.k_left = Input('left', 'a')
	self.k_right = Input('right', 'd')
	self.k_jump = Input('up', 'w')
    
    -- rectangle of whole players body
	self:addShape("main", "rectangle", {0, 0, 32, 32})	

    -- rectangle at players feet	
	self:addShape("jump_box", "rectangle", {4, 30, 24, 2})

    -- since we have two hitboxes, dont forget this! 
    -- Used to figure out where to place the sprite
	self:setMainShape("main")								
end

function entity0:update(dt)
	self.onCollision["main"] = function(other, sep_vector)
		if other.tag == "ground" then
			-- ceiling collision
            if sep_vector.y > 0 and self.vspeed < 0 then
                self:collisionStopY()
            end
            -- horizontal collision
            if math.abs(sep_vector.x) > 0 then
                self:collisionStopX() 
            end
		end
	end

	self.onCollision["jump_box"] = function(other, sep_vector)
        if other.tag == "ground" and sep_vector.y < 0 then
            -- floor collision
            self.can_jump = true 
        	self:collisionStopY()
        end 
    end

    if self.k_right() and not self.k_left() then
    	self.hspeed = 180
    end

    if self.k_left() and not self.k_right() then
    	self.hspeed = 180
    end

    if self.k_up() then
    	self:jump()
    end
end

function entity0:jump()
	if self.can_jump then
        self.vspeed = -700
        self.can_jump = false
    end	
end
```