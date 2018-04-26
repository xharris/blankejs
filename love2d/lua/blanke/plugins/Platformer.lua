Entity.addPlatforming = function(self, left, top, width, height)
	local margin = 5

	self:addShape("main_box", "rectangle", {left, top+margin, width, height-(margin*2)})		-- rectangle of whole players body
	self:addShape("jump_box", "rectangle", {left+margin, height-margin, width-(margin*2), margin})	-- rectangle at players feet
	self:addShape("head_box", "rectangle", {left+margin, top+self.sprite_yoffset, width-(margin*2), margin})
	self:setMainShape("main_box")
end

Entity.platformerCollide = function(self, ground_tag, fn_wall, fn_ceil, fn_floor)
	self.onCollision["main_box"] = function(other, sep_vector)	-- other: other hitbox in collision
		if other.tag == ground_tag then
            -- horizontal collision
            if math.abs(sep_vector.x) > 0 then
                self:collisionStopX() 
                if fn_wall then fn_wall() end
            end
		end
	end
	
	self.onCollision["head_box"] = function(other, sep_vector)
		if other.tag == ground_tag then
			-- ceiling collision
            if sep_vector.y > 0 and self.vspeed < 0 then
                self:collisionStopY()
                if fn_ceil then fn_ceil() end
            end
		end
	end
	
	self.onCollision["jump_box"] = function(other, sep_vector)
        if other.tag == ground_tag and sep_vector.y < 0 then
            -- floor collision
        	self:collisionStopY()
        	if fn_floor then fn_floor() end
        end 
    end
end