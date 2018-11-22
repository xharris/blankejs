BlankE.addEntity("Penguin");

function Penguin:init()
	self:addAnimation{name="stand", image="Basic Bird", frames={1,1,1,1}, frame_size={23,22}, speed=0, offset={0,0}}

	self:addPlatforming(0,0,23,22)
	self:platformerCollide("ground")
	
	Debug.log("here")
end

function Penguin:update(dt)

end

function Penguin:draw()

end
