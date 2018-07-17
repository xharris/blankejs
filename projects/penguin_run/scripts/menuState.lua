BlankE.addClassType("MenuState", "State")

local scene_igloo
local penguin

local leave_x

-- menu images
local img_peng_outline, img_earth
local img_hat

local menu_left = 194
local menu_width = 500 - menu_left
local menu_top = 130
local section_w = menu_width / 3

local igloo_font = Font{
	size=20,
	color="black",
	align="center"
}

function MenuState:enter(previous)
	self.background_color = Draw.black
	scene_igloo = Scene("igloo")
	penguin = Penguin(true)
	
	scene_igloo:addHitbox("ground")
	leave_x = scene_igloo:getObjects("penguin_spawn2")["layer0"][1][1]
	
	-- position the penguin
	if previous == "PlayState" then
		-- penguin walking in from outside
		scene_igloo:addEntity("penguin_spawn2", penguin, "bottom right")
	else
		-- penguin spawned in igloo
		scene_igloo:addEntity("penguin_spawn1", penguin, "bottom left")
	end
	
	-- get menu images
	img_peng_outline = Image("penguin_outline")
	img_peng_outline:setScale(2)
	
	img_earth = Image("menu_earth")
end

function MenuState:update(dt)
	-- penguin cannot jump and walks slower
	penguin.can_jump = 0
	penguin.walk_speed = 360
	
	-- penguin wants to leave igloo
	if penguin.x > leave_x then
		State.transition(PlayState, "circle-in")
	end
end

function refreshMenuHat()
	if Image.exists('hat/'..Penguin.main_penguin_info.hat) then
		img_hat = Image('hat/'..Penguin.main_penguin_info.hat)
		local animated = (img_hat.width > 32)
		if animated then
			img_hat = img_hat:crop(0,0,img_hat.width/2,img_hat.height)
		end

		img_hat:setScale(2)
		img_hat.x = menu_left + (section_w/2) - (img_hat.width/2)
		img_hat.y = menu_top + (section_w/2) - (img_hat.height/2)
	end
	img_peng_outline.x = menu_left + (section_w/2) - (img_peng_outline.width/2)
	img_peng_outline.y = menu_top + (section_w/2) - (img_peng_outline.height/2)
end

local circle_alpha = {80,80,80}
function MenuState:draw()
	scene_igloo:draw("layer0")
	
	-- draw menu
	local penguin_section = 0
	for c = 0,2 do
		local sect_left = menu_left + (section_w*c)
		local sect_right =  sect_left + section_w
		local peng_midx = penguin.x + (penguin.sprite_width/2)
		
		-- draw background rect
		Draw.setColor("white")
		if penguin.x > sect_left and penguin.x < sect_right then
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
		penguin:setColor()
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
		penguin:setColor()
		penguin:setHat()
		refreshMenuHat()
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
		penguin:setColor()
		penguin:setHat()
		refreshMenuHat()
	end

	-- draw penguin color
	Draw.setColor(penguin:getColor())
	local rect_margin = 10
	local rect_margin2 = 5
	Draw.setAlpha(.5)
	Draw.rect("fill", menu_left + section_w + rect_margin2 + (section_w/2) - (section_w/2), menu_top + rect_margin2, section_w - (rect_margin2*2), section_w - (rect_margin2*2))
	Draw.setAlpha(1)
	Draw.rect("fill", menu_left + section_w + rect_margin + (section_w/2) - (section_w/2), menu_top + rect_margin, section_w - (rect_margin*2), section_w - (rect_margin*2))
	
	-- draw earth icon
	img_earth.x = (menu_left + (section_w*2)) + (section_w/2) - (img_earth.width/2)
	img_earth.y = menu_top
	img_earth:draw()
	
	-- draw multiplayer status
	igloo_font:set('limit', section_w)
	Draw.setFont(igloo_font)
	Draw.text(play_mode, menu_left + (section_w*2) + (section_w/2) - (section_w/2), menu_top - igloo_font:get('size'))
		
	Draw.translate(-penguin.x, -penguin.y - 20)
	Draw.scale(2)
	Draw.setColor('white')
	penguin:draw()
	Draw.reset()
	
	scene_igloo:draw("layer1")
		
	-- draw outfit
	img_peng_outline:draw()
	if img_hat and Penguin.main_penguin_info.hat ~= "none" then
		img_hat:draw()
	else
		refreshMenuHat()
	end
	
end