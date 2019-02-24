BlankE.addEntity("Bullet")

Bullet.net_sync_vars = {'speed','direction'}

function Bullet:init()
	self.speed = 800
	self:addShape("main","circle",{0,0,1})
	Timer(1.5):after(function() self:destroy() end):start()
	
	Net.addObject(self)
end

function Bullet:update(dt)
	if self.x > game_width then self.x = 0 end
	if self.x < 0 then self.x = game_width end
	if self.y > game_height then self.y = 0 end
	if self.y < 0 then self.y = game_height end
	
	self.onCollision["main"] = function(other, sep_vec)
		if other.parent.classname == "Asteroid" then
			if not self.net_object then
				Signal.emit('score',other.parent.points)
			end
			
			other.parent:hit(other.parent.direction)
			self:destroy()
		end
	end
end

function Bullet:draw()
	Draw.setColor("white")
	Draw.circle("fill",self.x,self.y,1)
end