BlankE.addEntity("Npc")

local NPC_TYPE = {NONE=1} -- has other virus names
local eff_selected = Effect("chroma shift")

function Npc:init()
	self.penguin = Penguin()
	self.penguin.x = randRange(0, game_width)
	self.penguin.y = randRange(0, game_height)
	
	self.type = NPC_TYPE.NONE
	self.selected = false
	
	self.target_x = self.penguin.x 
	self.target_y = self.penguin.y
	self.travel_range = 20
	self.travel_speed = randRange(0,1)
	
	self.color = "blue"
	self.new_action_timer = Timer()
	self:nextAction()
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
	if not target_set then
		self.target_x = math.min(math.abs(randRange(self.penguin.x-self.travel_range, self.penguin.x+self.travel_range)), game_width)
		self.target_y = math.min(math.abs(randRange(self.penguin.y-self.travel_range, self.penguin.y+self.travel_range)), game_height)
			
		local closest_cart = FoodCart.instances:closestPoint(self.x, self.y)
		
		if self.travel_speed > 0 then
			self.travel_speed = 0 
		else
			self.travel_speed = randRange(20,40)
		end
		
	end
	
	self.penguin:moveTowardsPoint(self.target_x, self.target_y, self.travel_speed)
	
	self.new_action_timer:start()
end

function Npc:update(dt)
	if self:distancePoint(self.target_x, self.target_y) <= 1 then
		-- stand at a food cart and wait for food
		self.penguin.speed = 0
	end
	self.y = self.penguin.y
end

function Npc:draw()	
	local dist = self.penguin:distancePoint(mouse_x, mouse_y)
	
	if true then --dist < 100 then
		eff_selected.radius = dist / 20
		eff_selected:draw(function()
			self.penguin:draw()
		end)
	else
		self.penguin:draw()
	end
end
