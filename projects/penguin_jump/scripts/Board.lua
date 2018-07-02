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
	
	self.x = x
	self.y = y
	
	self.block_x = self.x - (block_width/2)
	self.block_y = self.y - (block_height/2)
end

function IceBlock:update(dt)
	self.mouse_inside = (self:distancePoint(mouse_x, mouse_y) < block_width)
	
	if self.can_select and Input("select") and self.mouse_inside then
		self.selected = true
	end
end

function IceBlock:draw()	
	-- draw selection circle if mouse is near
	if self.visible and not self.occupied and self.mouse_inside then
		Draw.setColor('grey')
		Draw.circle('fill', self.x, self.y, block_width)
	end
	
	if self.visible then
		Draw.setColor("black")
	elseif self.occupied then
		Draw.setColor("indigo")
	else	
		Draw.setColor("gray")
	end
	Draw.rect('line', self.block_x, self.block_y, block_width, block_height)
	
	if self.selected then
		Draw.setColor('red')s
		Draw.rect('line', self.block_x - 2, self.block_y - 2, block_width + 4, block_height + 4)
	end
end

--[[

	-Player

]]
BlankE.addEntity("Player")

function Player:init()
	
end

function Player:draw()
	Draw.setColor("blue")
	Draw.rect("fill", self.x - (block_width/2) + 5, self.y - block_height, block_width - 10, block_height)
end

--[[

	-Board

]]
BlankE.addEntity("Board")

local block_spacing_ratio = 2
function Board:init(size)
	self.blocks = Group()
	self.player = nil
	
	self.size = size
	
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

-- only use this for setting main player
function Board:addPlayer(x, y)
	local block = self.blocks:get(map2Dindex(x, y, self.size))
	self.player = Player()
	self.player.x = block.x
	self.player.y = block.y
	self.player.block_ref = block
	
	self:checkBlockVis()
end

-- Vis -> Visibility
function Board:checkBlockVis()
	self.blocks:forEach(function(b, block)
		block.visible = (math.abs(self.player.block_ref.grid_x - block.grid_x) <= 2 and
						 math.abs(self.player.block_ref.grid_y - block.grid_y) <= 2)
		block.occupied = (block == self.player.block_ref)
	end)
end

function Board:startMoveSelect()
	self.blocks:forEach(function(b, block)
		if block.visible and not block.occupied then
			block.can_select = true
		end
	end)
end

function Board:draw()
	self.blocks:call("draw")
	self.player:draw()
end