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

Entity("Card",{
		name='', -- number / draw / skip / reverse
		value=-1,
		color='black2',
		style='hand',
		align='center',
		scale=1, --.2,
		visible=false,
		--effect = {'static', 'chroma shift'},
		spawn = function(self, str)
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
		end,
		randomize = function(self)
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
			end
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
		end,
		drawRect = function(self)
			if self.rect then
				Draw{
					{'color','white', 0.5},
					{'poly','fill',unpack(self.rect)}
				}
			end
		end,
		draw = function(self)
			if self.visible then
				if self.style == "hand" then
					local r = 12
					Draw.push()
					Draw {
						--{'translate',-self.width/2,-self.height/2},
						--{'scale',self.scale,self.scale},
						--{'rotate',self.angle},
						--{'translate',self.x,self.y},
						{'color',self.color},
						{'rect','fill',0,0,card_w/2,card_h/2,r,r},
						{'color','black2',0.2},
						{'lineWidth', 1},
						--{'rect','line',0,0,card_w/2,card_h/2,r,r},
					}
					Draw.color('white')
					local ev = self.ent_value
					ev.x, ev.y = self.x, self.y
					ev.angle = 0
					--ev:draw()
					Draw.pop()
				end
			end
		end
})

Entity("card_text",{
		text='',
		add=false,
		image=nil,
		font_size=18,
		align='center',
		spawn = function(self)
			self.width, self.height = 18, 18
			if self.image and self.image ~= 'wild' then self.image = Image(self.image..'.png') end
			self:remDrawable()
		end,
		draw = function(self)
			if self.image and self.image ~= 'wild' then
				self.width, self.height = self.image.width, self.image.height
				self.image.x, self.image.y = 5,5
				self.image:draw()
			else
				Draw{
					{'color','white'},
					{'font','CaviarDreams_Bold.ttf',18},
					{'print',self.add and '+' or '',0,0},--5,8},
					{'print',self.text,14,10},
				}
			end
		end
})