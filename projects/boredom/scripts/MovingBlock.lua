BlankE.addEntity("MovingBlock")

function MovingBlock:init()
	self.block = Block(self.scene_rect)
	self.block.x = self.x
	self.block.y = self.y
	
	if self.scene_tag ~= '' then self.block.move_dir = self.scene_tag end
end

function MovingBlock:setMoveDir(dir)
	self.block.move_dir = dir
end

function MovingBlock:update(dt)
	self.block.collisionCB = function(block, other, sep)
		if other.tag == "ground" and not block.move_dir then
			if sep.x < 0 then block.move_dir = "R" end
			if sep.x > 0 then block.move_dir = "L" end
			if sep.y > 0 then block.move_dir = "U" end
			if sep.y < 0 then block.move_dir = "D" end
		end
		
		if other.tag == "Player.feet_box" and block.hspeed == 0 then
			if block.move_dir == "R" then
				block.move_tween = Tween(block, {hspeed=100}, 1, "quadratic in")
				block.move_tween:play()
			end
			if block.move_dir == "L" then
				block.move_tween = Tween(block, {hspeed=-100}, 1, "quadratic in")
				block.move_tween:play()
			end
			if block.move_dir == "D" then
				block.move_tween = Tween(block, {vspeed=100}, 1, "quadratic in")
				block.move_tween:play()
			end
		end
	end
end

function MovingBlock:draw()
	self.block:draw()
end