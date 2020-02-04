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
		value=0,
		color='black2',
		style='hand',
		align='center',
		scale=1, --.2,
		visible=false,
		--effect = {'static', 'chroma shift'},
		spawn = function(self, str)
			if card_names:includes(str) then
				self.name = str
				if str == 'wilddraw' then self.value = 4 end
				if str == 'draw' then self.value = 2 end
			else
				self.name = 'number'
				self.value, self.color = unpack(str:split('.'))
			end
		end,
		randomize = function(self)
			if self.value ~= 0 then
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
			if self.last_style ~= self.style then
				self.last_style = self.style 
				self.rect = {0,0,0,0}
			end
			if self.style == "hand" then
				self.width = card_w/2
				self.height = card_h/2
				self.rect = calcCardRect(self)
				
				if self.focused then
					--if self.twn_scale then self.twn_scale:stop() end
					if not self.twn_scale then
						self.twn_scale = Tween(1, self, {scale=1.25})
					end
					self.focused = false
				else
					--self.twn_scale = Tween(1, self, {scale=1})
				end
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
					self.width = card_w/2
					self.height = card_h/2
					local r = 15
					Draw{
						{'push'},
						{'color',self.color},
						{'rect','fill',0,0,card_w/2,card_h/2,r,r},
						{'color','black2'},
						{'lineWidth', 1},
						{'rect','line',0,0,card_w/2,card_h/2,r,r},
						{'pop'}
					}
				end
			end
		end
})