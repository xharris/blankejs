BlankE.addClassType("Igloo", "Entity")

local menu_left = 194
local menu_width = 500 - menu_left
local menu_top = 130
local section_w = menu_width / 3

local igloo_font = Font{
	size=20,
	color="black",
	align="center"
}

function Igloo:init(from_outside)	
	-- setup igloo 
	self.img_igloo_back = Image("in_igloo_back")
	self.img_igloo_outline = Image("in_igloo_outline")
	self.img_peng_outline = Image("penguin_outline")
	self.img_peng_outline:setScale(2)
	self.main_penguin = Penguin(true)

	self.img_igloo_back.x = self.x
	self.img_igloo_back.y = self.y

	self.igloo_exit_x = game_width - 100

	self.igloo_bottom = 605
	self.igloo_left = 257
	
	-- setup menu
	self.img_earth = Image("menu_earth")
	self:refreshMenuHat()
		
	-- igloo hitboxes
	self:addShape("bottom", "rectangle", {
		game_width,
		self.igloo_bottom + 33,
		game_width,
		33
	}, "ground")
	self:addShape("wall", "rectangle", {self.igloo_left-16, 0, 32, 600}, "ground")

	-- add player and upscale its sprite
	self.main_penguin.x = self.igloo_left
	self.main_penguin.y = 284
	if from_outside then
		self.main_penguin.x = self.igloo_exit_x - 5
		self.main_penguin.sprite_xscale = -1
	end
	self.main_penguin.sprite_yoffset = -24

	-- igloo furniture
	self.ent_closet = nil
end

function Igloo:update(dt)
	self.onCollision["closet"] = function(other, sep_vector)
		if other.tag:contains("Penguin") and Input('confirm') then
			if not self.ent_closet or self.ent_closet._destroyed then
				self.ent_closet = OutfitMenu(self.main_penguin)
			end
		end
	end

	-- penguin control
	self.main_penguin.can_jump = 0
	self.main_penguin.walk_speed = 360
	
	-- leaving igloo
	if self.main_penguin.x > self.igloo_exit_x then
		State.transition(playState, 'circle-in')
	end
end

function Igloo:refreshMenuHat()
	if Image.exists('hat/'..Penguin.main_penguin_info.hat) then
		self.img_hat = Image('hat/'..Penguin.main_penguin_info.hat)
		local animated = (self.img_hat.width > 32)
		if animated then
			self.img_hat = self.img_hat:crop(0,0,self.img_hat.width/2,self.img_hat.height)
		end

		self.img_hat:setScale(2)
		self.img_hat.x = menu_left + (section_w/2) - (self.img_hat.width/2)
		self.img_hat.y = menu_top + (section_w/2) - (self.img_hat.height/2)
	end
	self.img_peng_outline.x = menu_left + (section_w/2) - (self.img_peng_outline.width/2)
	self.img_peng_outline.y = menu_top + (section_w/2) - (self.img_peng_outline.height/2)
end

local circle_alpha = {80,80,80}
function Igloo:draw()
	self.img_igloo_back:draw()

	local penguin_section = 0
	for c = 0,2 do
		local sect_left = menu_left + (section_w*c)
		local sect_right =  sect_left + section_w
		local peng_midx = self.main_penguin.x + (self.main_penguin.sprite_width/2)
		
		-- draw background rect
		Draw.setColor("white")
		if self.main_penguin.x > sect_left and self.main_penguin.x < sect_right then
			-- player inside area
			if circle_alpha[c+1] < 150 then
				circle_alpha[c+1] = circle_alpha[c+1] + 5
			end
			penguin_section = c+1
		else
			if circle_alpha[c+1] > 0 then
				circle_alpha[c+1] = circle_alpha[c+1] - 5
			end
		end
		Draw.setAlpha(circle_alpha[c+1])
		Draw.rect("fill", menu_left + (section_w*c), 0, section_w, game_height)
	end
	
	-- menu control
	if Input('confirm') then
		-- color
		if penguin_section == 2 then
			Penguin.main_penguin_info.color_index = Penguin.main_penguin_info.color_index + 1
			if Penguin.main_penguin_info.color_index > 3 then
				Penguin.main_penguin_info.color_index = 1
			end
		end
		self.main_penguin:setColor()
	end
	if Input('menu_down') then
		-- hat
		if penguin_section == 1 then
			local hat_name = Penguin.main_penguin_info.hat
			local hat_index = table.find(Penguin.hats, hat_name)
			hat_index = hat_index - 1
			if hat_index < 1 then hat_index = #Penguin.hats end
			Penguin.main_penguin_info.hat = Penguin.hats[hat_index]
		end
		-- color
		if penguin_section == 2 then
			local color_name = Penguin.main_penguin_info.str_color
			local color_index = table.find(UI.color_names, color_name)
			color_index = color_index - 1
			if color_index < 1 then color_index = #UI.color_names end
			Penguin.main_penguin_info.str_color = UI.color_names[color_index]
		end
		self.main_penguin:setColor()
		self.main_penguin:setHat()
		self:refreshMenuHat()
	end
	if Input('menu_up') then
		-- hat
		if penguin_section == 1 then
			local hat_name = Penguin.main_penguin_info.hat
			local hat_index = table.find(Penguin.hats, hat_name)
			hat_index = hat_index + 1
			if hat_index > #Penguin.hats then hat_index = 1 end
			Penguin.main_penguin_info.hat = Penguin.hats[hat_index]
		end
		-- color
		if penguin_section == 2 then
			local color_name = Penguin.main_penguin_info.str_color
			local color_index = table.find(UI.color_names, color_name)
			color_index = color_index + 1
			if color_index > #UI.color_names then color_index = 1 end
			Penguin.main_penguin_info.str_color = UI.color_names[color_index]
		end
		self.main_penguin:setColor()
		self.main_penguin:setHat()
		self:refreshMenuHat()
	end

	-- draw penguin color
	Draw.setColor(self.main_penguin:getColor())
	local rect_margin = 10
	local rect_margin2 = 5
	Draw.setAlpha(.5)
	Draw.rect("fill", menu_left + section_w + rect_margin2 + (section_w/2) - (section_w/2), menu_top + rect_margin2, section_w - (rect_margin2*2), section_w - (rect_margin2*2))
	Draw.setAlpha(1)
	Draw.rect("fill", menu_left + section_w + rect_margin + (section_w/2) - (section_w/2), menu_top + rect_margin, section_w - (rect_margin*2), section_w - (rect_margin*2))
	
	-- draw earth icon
	self.img_earth.x = (menu_left + (section_w*2)) + (section_w/2) - (self.img_earth.width/2)
	self.img_earth.y = menu_top
	self.img_earth:draw()
	
	-- draw multiplayer status
	igloo_font:set('limit', section_w)
	Draw.setFont(igloo_font)
	Draw.text(play_mode, menu_left + (section_w*2) + (section_w/2) - (section_w/2), menu_top - igloo_font:get('size'))
		
	Draw.translate(-self.main_penguin.x, -self.main_penguin.y)
	Draw.scale(2)
	Draw.setColor('white')
	self.main_penguin:draw()
	Draw.reset()
	
	self.img_igloo_outline:draw()
	
	-- draw outfit
	self.img_peng_outline:draw()
	if self.img_hat and Penguin.main_penguin_info.hat ~= "none" then
		self.img_hat:draw()
	else
		self:refreshMenuHat()
	end
end