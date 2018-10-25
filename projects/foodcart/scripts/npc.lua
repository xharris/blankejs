BlankE.addEntity("Npc")

local TRAVEL_MODE = {WANDER=1,BEELINE=2,STAND=3,QUEUED=4}
local MOOD = {HUNGRY=1,NORMAL=2}

function Npc:init()
	self.x = randRange(0, game_width)
	self.y = randRange(0, game_height)
	
	self.hunger = 0
	self.mood = MOOD.NORMAL

	self.target_x = self.x 
	self.target_y = self.y
	self.travel_range = 20
	self.travel_speed = randRange(0,1)
	self.travel_mode = TRAVEL_MODE.WANDER
	
	self.target_cart = nil
	
	self.color = "blue"
	self.new_action_timer = Timer()
	self:nextAction()
end

function Npc:addHunger(amt)
	if self.hunger >= 3 then
		self.mood = MOOD.HUNGRY
		self.travel_mode = TRAVEL_MODE.BEELINE
	else	
		self.hunger = self.hunger + amt
	end
end

function Npc:subHunger(amt)
	self.hunger = self.hunger - amt
	-- not hungry anymore, wander around
	if self.hunger < 0 then
		self.travel_mode = TRAVEL_MODE.WANDER
	end
end

function Npc:getFood(obj_food)
	self:subHunger(self.hunger - obj_food.fill_amount)
end

function Npc:setTarget(x, y)
	self.target_x = x
	self.target_y = y
end

function Npc:nextAction()	
	self.new_action_timer.duration = randRange(1,5)
	self.new_action_timer:after(function()
		self:nextAction()	
	end)
	
	-- walk around randomly
	if self.travel_mode == TRAVEL_MODE.WANDER then
		self.target_x = randRange(self.x-self.travel_range, self.x+self.travel_range)
		self.target_y = randRange(self.y-self.travel_range, self.y+self.travel_range)
		if self.travel_speed > 0 then
			self.travel_speed = 0 
			self:addHunger(1)
		else
			self.travel_speed = randRange(15,18)
			self:addHunger(2)
		end
		
	end
		
	if self.mood == MOOD.HUNGRY then
		local closest_cart = FoodCart.instances:closestPoint(self.x, self.y)
		
		-- re-evaluate carts. go towards any possible better choices
		if self.target_cart then
			-- ...
		end
		
		-- start moving towards the closest cart
		if self.travel_mode ~= TRAVEL_MODE.STAND and closest_cart and not self.target_cart then
			self.target_x, self.target_y = closest_cart:addToLine(self)
			self.travel_speed = randRange(100,150)--20, 23)
			self.target_cart = closest_cart
		end
	end
	
	if self.travel_mode ~= TRAVEL_MODE.STAND then
		self:moveTowardsPoint(self.target_x, self.target_y, self.travel_speed)
	end
	self.new_action_timer:start()
end

function Npc:update(dt)
	if self:distancePoint(self.target_x, self.target_y) <= 1 then
		self.speed = 0
		self.target_cart = nil
		self.travel_mode = TRAVEL_MODE.QUEUED
	
		-- stand at a food cart and wait for food
		if self.mood == MOOD.HUNGRY then
			self.travel_mode = TRAVEL_MODE.QUEUED
		end
	end
end

function Npc:draw()
	Draw.setColor("black")
	Draw.circle("line", self.x - 5, self.y - 5, 10)
	Draw.text(self.hunger, self.x, self.y)
	Draw.setColor(self.color)
	Draw.circle("fill", self.x - 5, self.y - 5, 10)
	Draw.reset()
end
