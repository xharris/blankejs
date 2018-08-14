Repeater = Class{
	init = function(self, texture)
		if texture.classname then
			if texture.classname == "Image" then end
			if texture.classname == "" then end
		end
	end
}

return Repeater