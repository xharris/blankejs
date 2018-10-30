BlankE.addEntity("Npc")

local TRAVEL_MODE = {WANDER=1,BEELINE=2,STAND=3}
local MOOD = {HUNGRY=1,NORMAL=2}
local ACTIVITY = {NONE=1,EATING=2,QUEUED=3}

function Npc:init()
	self.x = randRange(0, game_width)
	self.y = randRange(0, game_height)
	
	self:addAnimation{
		name = 'stand',
		image = 'penguin_outline',
		frames = {1,1},
		frame_size = {32,32}
	}
	self:addAnimation{
		name = 'eyes',
		image = 'penguin_eyes',
		frames = {'1-2', 1},
		frame_size = {32, 32},
		speed = .1
	}
	self:addAnimation{
		name = 'walk',
		image = 'penguin_outline',
		frames = {'1-2', 1},
		frame_size = {32, 32},
		speed = .1
	}
	self:addAnimation{
		name = 'walk_fill',
		image = 'penguin_filler',
		frames = {'1-2', 1},
		frame_size = {32, 32},
		speed = .1
	}
	self.sprite_xoffset = -16
	self.sprite['eyes'].speed = 0
	self.sprite['walk_fill'].color = Draw.blue
	
	self.hunger = randRange(-10,0)
	self.travel_mode = TRAVEL_MODE.WANDER
	self.mood = MOOD.NORMAL
	self.activity = ACTIVITY.NONE

	self.target_x = self.x 
	self.target_y = self.y
	self.travel_range = 20
	self.travel_speed = randRange(0,1)
	
	self.target_cart = nil
	
	self.queue_facing = 1
	self.color = "blue"
	self.new_action_timer = Timer()
	self:nextAction()
end

function Npc:addHunger(amt)
	if self.hunger >= 3 then
		self.mood = MOOD.HUNGRY
		self:setAI("BEELINE",nil,nil)
	else	
		self.hunger = self.hunger + amt
	end
end

function Npc:subHunger(amt)
	self.hunger = self.hunger - amt
	-- not hungry anymore, wander around
	if self.hunger < 0 then
		self:setAI("WANDER", "NORMAL", nil)
	end
end

function Npc:setAI(travel, mood, activity)
	self.travel_mode = ifndef(TRAVEL_MODE[travel], self.travel_mode)
	self.mood = ifndef(MOOD[mood], self.mood)
	self.activity = ifndef(ACTIVITY[activity], self.activity)
end

function Npc:resetAI()
	self:setAI("WANDER","NORMAL","NONE")
end

function Npc:getFood(obj_food)
	self:subHunger(self.hunger + obj_food.fill_amount)
	self:resetAI()
	self:setAI(nil, nil, "EATING")
	self.target_cart = nil
	self:setTarget(self.x - randRange(50, 60), self.y, true)
end

function Npc:setTarget(x, y, urgent)
	self.target_x = x
	self.target_y = y
	if urgent then
		self:nextAction(true)
	end
end

-- target_set : target_x/y is already set. don't use new random vals
function Npc:nextAction(target_set)	
	self.new_action_timer.duration = randRange(1,5)
	self.new_action_timer:after(function()
		self:nextAction()	
	end)
	
	-- walk around randomly
	if not target_set and self.travel_mode == TRAVEL_MODE.WANDER then
		function isTrespassing()
			local invading = false
			FoodCart.instances:forEach(function(c, cart)
				if cart:onProperty(self.target_x, self.target_y) then
					invading = true
					return true
				end
			end)
			return invading
		end
		
		repeat
			self.target_x = randRange(self.x-self.travel_range, self.x+self.travel_range)
			self.target_y = randRange(self.y-self.travel_range, self.y+self.travel_range)	
		until not isTrespassing() 
		
		local closest_cart = FoodCart.instances:closestPoint(self.x, self.y)
		
		
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
		if not target_set and self.travel_mode ~= TRAVEL_MODE.STAND and closest_cart and not self.target_cart then
			self.target_x, self.target_y, self.queue_facing = closest_cart:addToLine(self)
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
	-- walking animation
	if self.speed > 0 then
		self.sprite_speed = self.speed / 20
	else
		self.sprite_speed = 0
		self.sprite_frame = 1
	end
	self.sprite['eyes'].frame = 1	
	
	if self.target_cart and self:distancePoint(self.target_x, self.target_y) <= 1 then
		-- stand at a food cart and wait for food
		self.speed = 0
		--self.target_cart = nil
		self:setAI(nil, nil, "QUEUED")
	end
end

function Npc:postUpdate(dt)
	-- which way to face when standing in a line
	if self.activity == ACTIVITY.QUEUED and self.speed == 0 then
		self.sprite_xscale = self.queue_facing
	end
	if self.activity ~= ACTIVITY.QUEUED then	
		if self.hspeed < 0 then self.sprite_xscale = -1 end
		if self.hspeed > 0 then self.sprite_xscale = 1 end
	end
end

function Npc:draw()		
	self:drawSprite('walk')
	self:drawSprite('walk_fill')
	self:drawSprite("eyes")
	
	if UI.mouseInside(self.x - 16, self.y, 32, 32) then
		Draw.setColor("black")
		Draw.text(self.travel_mode..","..self.mood..","..self.activity, self.x, self.y)
	end
end
