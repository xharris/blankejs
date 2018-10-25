BlankE.addEntity("Food")

function Food:init()
	self.name = "burger"
	self.fill_amount = randRange(6,10)
end

BlankE.addEntity("FoodCart")

function FoodCart:init()
	self.line = Group() -- penguin queue waiting for food
	self.food = Group()
	
	self.prepare_timer = Timer()
	self.serve_timer = Timer()
	
	self.prepare_timer:every(function()
		self.food:add(Food())
	end, 1):start()
end

function FoodCart:draw()
	Draw.setColor("brown")
	Draw.rect("fill", self.x - 30, self.y - 20, 60, 40)
	Draw.setColor("black")
	Draw.text(self.food:size(), self.x - 30, self.y - 20)
	Draw.reset()
end

function FoodCart:getLineCoords(index)
	local columns = 3
	local x, y = map2Dcoords(index, columns)
	if y % 2 == 0 then x = (columns + 1) - x end -- this makes the line serpent-style

	x = self.x - 20 + ((x - 1) * 20)
	y = self.y + 25 + ((y - 1) * 20)

	return randRange(x-1, x+1), randRange(y-1, y+1)
end

-- serve the first penguin in line
function FoodCart:servePenguin()
	if self.line:size() > 0 and self.food:size() > 0 and self.line:get(1).speed == 0 then
		local penguin = self.line:remove(1)
		local food = self.food:remove(1) -- change later to remove specific food
		penguin:getFood(food)
		
		self:updateLine()
	end
end

function FoodCart:updateLine()
	self.line:forEach(function(p, penguin)
		local x, y = self:getLineCoords(p)
		penguin:setTarget(x, y)
	end)
end

-- returns coordinates of where to stand in the line
function FoodCart:addToLine(penguin)
	self.line:add(penguin)
		
	-- start serving food
	self.serve_timer:after(function()
		self:servePenguin()
		if self.line:size() > 0 then
			self.serve_timer:start()	
		end
	end)
	if not self.serve_timer.running then self.serve_timer:start() end
	
	return self:getLineCoords(self.line:size())
end

function FoodCart:removeFromLine(penguin) end
function FoodCart:updateLine() end
