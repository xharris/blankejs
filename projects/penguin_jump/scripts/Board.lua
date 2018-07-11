local main_view

--[[

	-Ice Block

]]
BlankE.addEntity("IceBlock")

local block_width = 30
local block_height = block_width-- block_width * .75
function IceBlock:init(x, y)
	self.occupied = false		-- a player is standing on this block
	self.visible = false		-- player can interact with this block
	self.can_select = false
	self.selected = false
	self.mouse_inside = false
	self.shrink_amount = 0
	self.sunk = false
	
	self.x = x
	self.y = y
	
	self.block_x = self.x - (block_width/2)
	self.block_y = self.y - (block_height/2)
	
	Signal.on('block_select', function(block)
		if block ~= self then
			self.selected = false
		end
	end)
end

function IceBlock:sink()
	if self.shrink_amount == 0 then
		self.shrink_amount = 0
		-- TODO: change later to shrink_amount_x, shrink_amount_y
		shrink_tween = Tween(self, {shrink_amount=block_width}, .5)
		shrink_tween.onFinish = function()
			self.sunk = true
		end
		shrink_tween:play()
	end
end

function IceBlock:update(dt)
	self.mouse_inside = (self:distancePoint(main_view:mousePosition()) < block_width and not self.sunk)
	
	if Input("select") and not self.sunk and self.can_select and self.visible and not self.occupied and not self.selected and self.mouse_inside then
		self.selected = true
		Signal.emit('block_select', self)
	end
end

function IceBlock:draw()	
	-- draw selection circle if mouse is near
	if self.visible and not self.occupied and self.mouse_inside then
		Draw.setColor('grey')
		Draw.circle('fill', self.x, self.y, block_width)
	end
	
	if self.shrink_amount > 0 then
		Draw.setColor("green")
		Draw.circle('line', self.x, self.y, block_width)
	end
	
	if self.visible then
		Draw.setColor("black")
	elseif self.occupied then
		Draw.setColor("indigo")
	else	
		Draw.setColor("gray")
	end
	Draw.rect('line', 
		self.block_x+self.shrink_amount / 2, 
		self.block_y+self.shrink_amount / 2, 
		block_width-self.shrink_amount / 2, 
		block_height-self.shrink_amount / 2
	)
	
	if self.selected then
		Draw.setColor('red')
		Draw.rect('line',
			self.block_x - 2,
			self.block_y - 2,
			block_width + 4,
			block_height + 4
		)
	end
end

--[[

	-Player

]]
BlankE.addEntity("Player")

Player.net_sync_vars = {"persistent","x","y","grid_x","grid_y","color","power"}
local net_player_list = {}
function Player:init()
	self.color = table.random(Draw.colors)
	while self.color == 'white' or self.color == 'white2' do self.color = table.random(Draw.colors) end
	self.moving = false
	self.power = 0
	self.grid_x = 0
	self.grid_y = 0
	self.knockback_block = nil
	
	self.move_curve = Bezier()
	self.move_tween = Tween(self, self.move_curve, 0.5, 'circular in')
	self.move_tween.onFinish = function()
		self.moving = false
		self.move_curve:clear()
		if self.knockback_block then self.knockback_block = nil end
		Signal.emit('finish_jump')
	end
	
	Signal.on('block_select', function(block)
		if not self.moving then
			self:setTargetBlock(block)
		end
	end)
end

function Player:getMoveInfo()
	return {x=self.grid_x, y=self.grid_y, power=self.power}
end

function Player:setTargetBlock(block)
	self.move_curve:clear()
	-- TODO: figure out why this order works
	self.move_curve:addPoint(self.x, self.y)
		:addPoint(block.x, block.y)
		:addPoint((block.x+self.x)/2, block.y - 150)
end

function Player:jumpToBlock(block)
	self:setTargetBlock(block)
	self.block_ref = block
	self.grid_x = block.grid_x
	self.grid_y = block.grid_y
	
	if self.move_curve:size() >= 2 then
		self.move_tween:setValue(self.move_curve)
		self.move_tween:play()
		main_view:follow(block)
		self.moving = true
	end
end

function Player:refreshPower()
	self.power = randRange(1,100)
end

function Player:draw()
	Draw.setColor(self.color)
	Draw.rect("fill", self.x - (block_width/2) + 5, self.y - block_height, block_width - 10, block_height)
	Draw.setColor('black')
	Draw.rect("line", self.x - (block_width/2) + 4, self.y - block_height - 1, block_width - 9, block_height + 1)
	Draw.text(self.power, self.x - (block_width / 2) + 4, self.y - (block_height*1.5))
end

--[[

	-Board

]]
BlankE.addEntity("Board")

local block_spacing_ratio = 2
local move_time = 3-- 10
local block_visibility = 5

function Board:init(size)
	main_view = View()
	main_view.motion_type = "damped"
	main_view.speed = 5
	
	self.blocks = Group()
	self.orig_size = size
	self.size = size
	self.resolving = false
	self.round = 1
	
	self:replacePlayer(Player())
	
	self.selecting_block = false
	self.selected_block = nil
	self.move_timer = Timer(move_time)
	
	self.move_timer:after(function()
		if Net.is_leader then
			Net.event("start_jump")
		end
	end)

	Signal.on('block_select', function(block)
		self.selected_block = block
	end)
		
	-- set up board
	local group_width = (block_width*block_spacing_ratio) * self.size - (block_width)
	local group_height = (block_height*block_spacing_ratio) * self.size - (block_height)
	local group_offsetx = (game_width / 2) - (group_width/2) + (block_width/2)
	local group_offsety = (game_height / 2) - (group_height/2) + (block_height/2)
	for x = 1,size do
		for y = 1,size do
			local new_block = IceBlock(
				(x - 1) * (block_width*block_spacing_ratio) + group_offsetx,
				(y - 1) * (block_height*block_spacing_ratio) + group_offsety
			)
			new_block.index = map2Dindex(x,y,size)
			new_block.grid_x = x
			new_block.grid_y = y
			
			self.blocks:add(new_block)
		end
	end
end

function Board:replacePlayer(new_player)
	if self.player then self.player:destroy() end
	self.player = new_player
end

-- only use this for setting main player
function Board:addPlayer(x, y)
	local block = self.blocks:get(map2Dindex(x, y, self.size))
	self.player.x = block.x
	self.player.y = block.y
	self.player.block_ref = block
	
	self:checkBlockVis()
end

function Board:movePlayer(x, y)
	self:getBlockAt(x,y,function(block)
		self.player:jumpToBlock(block)
	end)
end

function Board:getBlockAt(x, y, fn)
	self.blocks:forEach(function(b, block)
		if block.grid_x == x and block.grid_y == y then
			fn(block)
			return true
		end
	end)
end

function Board:clearSelection()
	self.selected_block = nil
end

function Board:movePlayerToBlock(block)
	Net.event("attempting_jump", {x=block.grid_x, y=block.grid_y})
	block.selected = false
	
	self.player:jumpToBlock(block)
	self:checkBlockVis()
end

function Board:performMove()
	self.selected_block = ifndef(self.selected_block, self.player.block_ref)
	self:movePlayerToBlock(self.selected_block)
end

-- 2 players on same block?
-- other_player: object having {x (gridx), y (gridy), power}
function Board:checkMoveConflict(other_player)
	if other_player.grid_x == self.player.grid_x and other_player.grid_y == self.player.grid_y then
		if other_player.power > self.player.power then
			-- LOSE, fly away
			local randx, randy = other_player.grid_x, other_player.grid_y
			local size_offset = self.orig_size - self.size
			while randx == other_player.grid_x and randy == other_player.grid_y do
				local random_set = {size_offset, self.orig_size - size_offset}
				randx, randy = randRange(unpack(random_set)), 
							   randRange(unpack(random_set))
			end
			self:getBlockAt(randx, randy, function(block)
				Signal.on('finish_jump',function()
					self.player.knockback_block = block
					self:movePlayerToBlock(self.player.knockback_block)
				end, true)
			end)
			return true
		else
			-- WIN, keep spot
		end
	end
	return false
end

-- Vis -> Visibility
function Board:checkBlockVis()
	self.blocks:forEach(function(b, block)
		block.visible = (math.abs(self.player.block_ref.grid_x - block.grid_x) <= block_visibility and
						 math.abs(self.player.block_ref.grid_y - block.grid_y) <= block_visibility)
		block.occupied = (block == self.player.block_ref)
	end)
end

-- for now... do not set size greater than initialization size
function Board:setSize(new_size)
	local size_offset = (self.orig_size - new_size)/2
	self.blocks:forEach(function(b, block)
		if block.grid_x <= size_offset or block.grid_y <= size_offset or 
		   block.grid_x >= self.orig_size - size_offset + 1 or block.grid_y >= self.orig_size - size_offset + 1 then
			block:sink()
		end
	end)
	self.size = new_size
end

function Board:startMoveSelect()
	self.selecting_block = true
	self.player:refreshPower()
	
	-- start block selection timer
	if Net.is_leader then self.move_timer:start() end
	
	-- mark blocks that are selectable
	self.blocks:forEach(function(b, block)
		block.selected = false
		block.can_select = true
	end)
end

function Board:draw()
	main_view:draw(function()
		self.blocks:call("draw")	
		Net.draw('Player')
		if self.player then
			self.player:draw()
		end
	end)
		
	Draw.setColor("black")
	Draw.text("time:"..math.abs(math.ceil(move_time - self.move_timer.time)).." round "..self.round, 20, 20)
end