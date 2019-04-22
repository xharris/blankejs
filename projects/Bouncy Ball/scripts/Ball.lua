BlankE.addEntity("Ball")

function Ball:init()
	self.img_ball = Image("ball")
	self.gravity = 0.5
	self:addShape('main','circle',{0,0,self.img_ball.width/2})
end

function Ball:update(dt)
	self.img_ball.x = self.x 
	self.img_ball.y = self.y
	
	self.onCollision['main'] = function(other)
		if other.parent.classname == "Paddle" then
			self:collisionBounce()
		end
	end
end

function Ball:draw()
	self.img_ball:draw()
end