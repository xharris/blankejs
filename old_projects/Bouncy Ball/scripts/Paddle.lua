BlankE.addEntity("Paddle")

function Paddle:init()
	-- add the image of a paddle
	self:addSprite{name="main",image="paddle",align="center"}
	-- give the Paddle friction so it won't move in one direction forever
	self.friction = 0.4
	-- add a hitbox
	self:addShape("main","rectangle")
end

function Paddle:update(dt)
	-- determine how fast it will move
	local move_spd = 500
	-- watch for key presses and move the paddle in the direction the player presses
	if Input("move_left").pressed then
		self.hspeed =	-move_spd
	end
	if Input("move_right").pressed then 
		self.hspeed =	move_spd 
	end 
	if Input("move_down").pressed then
		self.vspeed =	move_spd 
	end
	if Input("move_up").pressed then
		self.vspeed =	-move_spd
	end
	-- check if it is out of bounds horizontally
	-- 'teleport' it to the other side of the screen, if it goes out of bounds
	if self.x > game_width then
		self.x = 0
	end
	if self.x < 0 then
		self.x = game_width
	end
end

function Paddle:explode()
	-- set a flag and check it so that the paddle can't explode again
	if self.exploded then return end
	self.exploded = true
	-- break the paddle image into pieces 
	self.img_paddle_pcs = self:getImage():chop(8,5)
	-- throw them in random directions
	self.img_paddle_pcs:forEach(function(piece)
		local direction = randRange(0, 360)
		piece.hspeed = direction_x(direction, 20)
		piece.vspeed = direction_y(direction, 20)
	end)
	Signal.emit("paddle_explode")
	-- remove the hitbox so that it seems like it's actually exploded and gone
	self:removeShape("main")
	-- after some time, destroy the object
	Timer.after(3, function()
		self:destroy()
	end)
end

function Paddle:draw()
	-- draw the pieces
	-- hide the old image if it's exploded
	if self.img_paddle_pcs then
		self.img_paddle_pcs:call('draw')
	else
		self:drawSprite()
	end
end
