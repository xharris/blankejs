BlankE.addEntity("Mario");

function Mario:init()
	self:addAnimation{name="mario_walk", image="sprite-example", frames={"1-2",1,1,2}, frame_size={31,44}, speed=0.15, offset={41,8}}
	self.sprite_index = "mario_walk"
end

function Mario:update(dt)

end
