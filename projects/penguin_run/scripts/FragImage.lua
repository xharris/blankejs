BlankE.addEntity("Fragger")

function Fragger:init()
	self.frag_images = Group()
	self.canvases = Group()
end

function Fragger:add(obj)
	if obj.classname == "Scene" then
		local new_canvas = Canvas(obj.width, obj.height)
		new_canvas:drawTo(function()
			obj:draw()
		end)
		self.canvases:add(new_canvas)
	end
end

function Fragger:frag(x,y,w,h)
	
end

function Fragger:draw()
	self.main_canvas:draw()
	self.frag_images:forEach(function(f, obj)
		obj:draw()
	end)
	
	Draw.setColor("red")
	Draw.rect("line",self.x,self.y,self.main_canvas.width,self.main_canvas.height)
end

BlankE.addEntity("FragImage")

function FragImage:init(image, parent)
	if image.alpha == 0 then self:destroy() else
		self.parent = parent
		
		self.img_frags = image:chop(image.width/randRange(3,5),image.width/randRange(3,5))

		-- add gravity to images
		self.img_frags:forEach(function(f, frag)
			frag.random_g = randRange(7,10)
			frag.gravity = 0
		end)
	end
end

function FragImage:update(dt)	
	local wall_x = 0
	if wall then wall_x = wall.x end

	local drawn = 0
	self.img_frags:forEach(function(f, frag)
		
		frag.gravity = frag.gravity + frag.random_g
		frag.y = frag.y + frag.gravity * dt
		frag.x = frag.x - 15 * dt
			
		if frag.y < main_view.bottom then
			drawn = drawn + 1		
		end
	end)
	
	-- are all the frags destroyed?
	if drawn == 0 then
		self.img_frags:destroy()
		self:destroy()
		if self.parent then self.parent:destroy() end
	end
end

function FragImage:draw()
	if self.img_frags then
		self.img_frags:forEach(function(f, frag)
			frag:draw()
		end)
	end
end

