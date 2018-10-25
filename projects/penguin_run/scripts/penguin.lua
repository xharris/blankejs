BlankE.addEntity("Penguin")

local MAX_JUMPS = 3

Penguin.main_penguin_info = {
	str_color = 'blue',
	color_index = randRange(1,3),
	hat = "none"
}

Penguin.hats = Asset.list('image','hat')
table.insert(Penguin.hats, 'none')

Penguin.net_sync_vars = {'color','sprite_speed','sprite_xscale','color','hat','eyes'}

function Penguin:init(is_main_player)
	self:addAnimation{
		name = 'stand',
		image = 'penguin',
		frames = {1,1},
		frame_size = {32,32}
	}
	self:addAnimation{
		name = 'eyes',
		image = 'eyes',
		frames = {'1-2', 1},
		frame_size = {32, 32},
		speed = .1
	}
	self:addAnimation{
		name = 'walk',
		image = 'penguin',
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

	--self.friction = 0.05
	self.gravity = 35
	self.can_jump = MAX_JUMPS
	self.walk_speed = 260
	self.walk_accel = 20
	-- random shade of blue
	self.sprite_yoffset = -16
	self.sprite_xoffset = -16

	self:addPlatforming(0, 4, 15, 26)

	self.eyes = 1
	self.sprite['eyes'].speed = 0

	if is_main_player then
		self:setColor(self:getColor())
		self:setHat(Penguin.main_penguin_info.hat)
	end
end

function Penguin:getColor()
	return ifndef(UI.colors[Penguin.main_penguin_info.str_color][Penguin.main_penguin_info.color_index], UI.colors['blue'][randRange(1,3)])
end

function Penguin:setColor(value)
	value = ifndef(value, self:getColor())
	self.color = value
	local dark_colors = {{33,33,33,255}}

	-- make eyes white if it's a dark color
	self.sprite['eyes'].color = Draw.blue
	for d, dark_color in ipairs(dark_colors) do
		if value[1] == dark_color[1] and value[2] == dark_color[2] and value[3] == dark_color[3] and value[4] == dark_color[4] then
			self.sprite['eyes'].color = Draw.white
		end
	end
end

function Penguin:setEyes(value)
	self.eyes = value
	self.sprite['eyes'].frame = value
end

function Penguin:setHat(name)
	name = ifndef(name, Penguin.main_penguin_info.hat)
	self.hat = name
	
	if name == "none" and self.sprite['hat'] then
		self.sprite['hat'].alpha = 0
	end

	if Image.exists('hat/'..tostring(name)) then
		self.img_hat = Image('hat/'..name)
		local animated = (self.img_hat.width > 32)

		if animated then
			self:addAnimation{
				name = 'hat',
				image = 'hat/'..name,
				frames = {'1-2',1},
				frame_size = {32,32}
			}
		else
			self:addAnimation{
				name = 'hat',
				image = 'hat/'..name
			}
		end
	end
end

function Penguin:onNetUpdate(name, value)
	if name == 'hat' then
		self:setHat(value)
	end

	if name == 'color' then
		self:setColor(value)
	end

	if name == 'eyes' then
		self:setEyes(value)
	end
end

function Penguin:update(dt)
	local behind_wall = true
	if not wall or self.x > wall.x then
		behind_wall = false
	end
	if not best_penguin or self.x > best_penguin.x then
		best_penguin = self
	end
	
	self:platformerCollide{
		tag="ground",
		-- floor collision
		floor=function()
            self.can_jump = MAX_JUMPS 
		end	
	}
	
	-- left/right movement
	if not self.net_object then
		self.hspeed = 0
		if Input("player_right") > 0 then
			self.hspeed = self.walk_speed
			self:netSync('x','y')
		end
		if Input("player_left") > 0 then
			self.hspeed = -self.walk_speed
			self:netSync('x','y')
		end
		
		if Input("player_up") > 0 then
			self:jump()
			self:netSync('x','y')
		end
		self:netSync('hspeed','vspeed')

		if Input("emote1") == 1 then
			self:setEyes(2)
		end
	end

	-- animation
	if self.hspeed > 0 then
		self.sprite_xscale = 1
	elseif self.hspeed < 0 then
		self.sprite_xscale = -1
	end

	if self.hspeed == 0 then
		self.sprite_speed = 0
		self.sprite_frame = 1
	else
		self.sprite_speed = 2
	end

	if self.vspeed ~= 0 then
		self.sprite_speed = 0
		self.sprite_frame = 2
	end

	self:setEyes(self.eyes)
end

function Penguin:jump()
	if self.can_jump > 0 then
		self.vspeed = -900 + (100 * (self.can_jump / MAX_JUMPS))
		self.can_jump = self.can_jump - 1
	end
end

function Penguin:draw()
	--Draw.setColor('white')
	self.sprite['walk'].color = Draw.white
	self.sprite['walk_fill'].color = self.color

	self:drawSprite('walk')
	self:drawSprite('walk_fill')

	local eyes_y_offset = 0
	if (self.sprite_speed > 0 and self.sprite_frame == 2) or self.vspeed ~= 0 then
		eyes_y_offset = -1
	end
	self.sprite['eyes'].yoffset = eyes_y_offset
	self:drawSprite('eyes')

	-- draw penguin hat
	if self.img_hat then
		local hat_y_offset = -(self.img_hat.height - 32)
		if self.sprite_speed > 0 and self.sprite_frame == 2 and self.img_hat.width <= 32 then
			hat_y_offset = -(self.img_hat.height - 32) - 1
		end
		self.sprite['hat'].yoffset = hat_y_offset
	end
	--Debug.log("at",self.x,self.y)
	self:drawSprite('hat')
end