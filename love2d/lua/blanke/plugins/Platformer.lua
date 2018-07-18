Entity.addPlatforming = function(self, left, top, width, height)
	local left2 = left + self.sprite_xoffset
	local top2 = top + self.sprite_yoffset

	self:addShape("main_box", "rectangle", {left, top, width, height})		-- rectangle of whole players body
	self:addShape("head_box", "rectangle", {left, top-(height-2), width, 2})
	self:addShape("jump_box", "rectangle", {left, top+(height-2), width, 2})	-- rectangle at players feet
	self:setMainShape("main_box")
end

Entity.platformerCollide = function(self, ground_tag, fn_wall, fn_ceil, fn_floor)
	self.onCollision["main_box"] = function(other, sep_vector)	-- other: other hitbox in collision
		if other.tag == ground_tag then
            -- horizontal collision
            if math.abs(sep_vector.x) > 0 then
                if (fn_wall and fn_wall() ~= false) or fn_wall == nil then
	                self:collisionStopX() 
	            end
            end
		end
	end
	
	self.onCollision["head_box"] = function(other, sep_vector)
		if other.tag == ground_tag then
			-- ceiling collision
            if sep_vector.y > 0 and self.vspeed < 0 then
                if (fn_ceil and fn_ceil() ~= false) or fn_ceil == nil then
               		self:collisionStopY()
                end
            end
		end
	end
	
	self.onCollision["jump_box"] = function(other, sep_vector)
        if other.tag == ground_tag and sep_vector.y < 0 then
            -- floor collision
        	if (fn_floor and fn_floor() ~= false) or fn_floor == nil then
        		self:collisionStopY()
        	end
        end 
    end
end