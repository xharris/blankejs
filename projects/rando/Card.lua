card_names = Array('skip','draw','reverse','wild','wilddraw')
card_colors = Array('red','yellow','green','blue')

card_w = 212
card_h = 336

-- TODO: limit the number of draw cards
draw_card_count = 10

calcCardRect = function(card)
	local cx, cy, angle = card.x, card.y, math.rad(card.angle)
	local rotatePoint = function(x,y)
		-- apply rotation
		return {
			(x*math.cos(angle) - y*math.sin(angle)) + cx, 
			(x*math.sin(angle) + y*math.cos(angle)) + cy
		}
	end
	
	local w2, h2 = card.width * card.scale / 2, card.height * card.scale / 2
	local ul, ur, dl, dr = 
		rotatePoint(-w2, -h2),
		rotatePoint( w2, -h2),
		rotatePoint(-w2,  h2),
		rotatePoint( w2,  h2)
	return {ul[1], ul[2], ur[1], ur[2], dr[1], dr[2], dl[1], dl[2], ul[1], ul[2]}	
end

Effect.new('tablecard',{
	effect=[[
		float size = 2.0;
		float size_y = 2.0;
		texture_coords.x *= lerp(size,1,texture_coords.y);
		texture_coords.x -= lerp(1/size,0,texture_coords.y);
		texture_coords.y *= size_y;
		texture_coords.y -= 1/size_y;
		pixel = Texel(texture, texture_coords);
	]]
})

Entity("Card",{
	name='', -- number / draw / skip / reverse
	value=-1,
	color='black2',
	style='hand',
	scale=1, --.2,
	visible=false,
	effect = { 'static','chroma shift' },
	spawn = function(self, str)	
		self.effect:set("static", "strength", {20, 0})
		--self.effect:disable('static','chroma shift')

		local pos_name = str:split('.')[1]
		if card_names:includes(pos_name) then
			self.name = pos_name
			if self.name == 'wilddraw' then self.value = 4 end
			if self.name == 'draw' then self.value = 2 end
			if not self.name:contains('wild') then
				self.name, self.color = unpack(str:split('.'))
			end				
		else
			self.name = 'number'
			self.value, self.color = unpack(str:split('.'))
			self.value = tonumber(self.value)
		end
		if self.name == "skip" or self.name == "reverse" then
			self.image = Image(self.name..".png")
		end
		-- numbers on card
		if self.value >= 0 then
			self.ent_value = Game.spawn("card_text", {text=self.value, add=self.name:contains('draw')})
		else
			self.ent_value = Game.spawn("card_text", {image=self.name})
		end
		self.orig = {value=self.value, color=self.color, name=self.name}
	end,
	randomize = function(self)
		if not be_random() then return end
		Timer.after(0.5,function()
			self.effect:enable('static','chroma shift')
			Timer.after(0.5,function()
				if self.value >= 0 then
					local new_val = self.value
					while new_val == self.value do
						new_val = Math.random(1,9)
					end
					self.value = new_val
				end
				if self.color ~= 'black2' then
					local new_color = self.color
					while new_color == self.color do
						new_color = table.random(card_colors.table)
					end
					self.color = new_color
				end

				self.effect:disable('static','chroma shift')
			end)
		end)
	end,
	__ = {
		tostring = function(self)
			return self.name..'.'..self.value..(self.color and '.'..self.color or '')
		end
	},
	update = function(self, dt)
		if self.value >= 0 then 
			self.ent_value.text = tostring(self.value)
		end
		if self.last_style ~= self.style then
			self.last_style = self.style 
			self.rect = {0,0,0,0}
			-- self.effect:set("tablecard", self.rect)
		end
		-- card in hand
		if self.style == "hand" then
			self.width = card_w/2
			self.height = card_h/2
			self.rect = calcCardRect(self)

			if self.focused then
				self.target_scale = 1.25
				self.focused = false
			else
				self.target_scale = 1
			end
			self.scale = Math.lerp(self.scale, self.target_scale, 0.5)
		end
		-- card on table
		if self.style == 'table' then
			self.width = card_w/5
			self.height = card_h/5
			self.scale = 0.6
			self.rect = calcCardRect(self)
		end
	end,
	drawRect = function(self)
		if self.rect then
			Draw{
				{'color','blue', 0.5},
				{'poly','fill',unpack(self.rect)}
			}
		end
	end,
	draw = function(self)
		if self.style == "hand" or self.style == 'table' then
			local r = 12
			Draw.push()
			Draw {
				{'color',self.color},
				{'rect','fill',-card_w/4,-card_h/4,card_w/2,card_h/2,r,r},
				{'color','black2',0.2},
				{'lineWidth', 1},
			}
			Draw.pop()
			Draw.color('white')
			local ev = self.ent_value
			if self.color == 'yellow' then
				ev.color = 'black2'
			else 
				ev.color = 'white2'
			end
			ev.big = false
			-- top left
			ev.x, ev.y, ev.angle = -card_w/4, -card_h/4, 0
			ev:draw()
			-- bottom right
			ev.x, ev.y, ev.angle = card_w/4, card_h/4, 180
			ev:draw()
			-- center
			ev.big = true
			ev.x, ev.y, ev.angle = 0, 0, 0
			ev:draw()
		end
	end
})

Entity("card_text",{
	text='',
	add=false,
	image=nil,
	font_size=18,
	color='white2',
	big=false,
	spawn = function(self)
		if self.image and self.image ~= 'wild' then 
			self.image = Image(self.image..'.png')
			self.width, self.height = self.image.width, self.image.height
		else 
			self.width, self.height = 12, 16
		end
		self:remDrawable()
	end,
	draw = function(self)
		Draw.color(self.color)
		if self.image and self.image ~= 'wild' then
			if self.big then 
				self.image.x = 0
				self.image.y = 0
				self.image.scale = 2.5
				self.image.align = "center"
			else	
				self.image.x = 5
				self.image.y = 5
				self.image.scale = 1
				self.image.align = "top left"
			end
			self.image:draw()
		else
			Draw.font('CaviarDreams_Bold.ttf',self.big and 30 or 18)
			local txt = (self.add and '+' or '')..self.text
			if self.big then
				local fnt = Draw.getFont()
				Draw.print(txt,-fnt:getWidth(txt)/2,-fnt:getHeight()/2,nil,"center")
			else 
				Draw.print(txt,10,10,nil,"center")
			end				
		end
	end
})