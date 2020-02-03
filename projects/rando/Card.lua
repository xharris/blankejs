card_names = Array('skip','draw','reverse','wild','wilddraw')
card_colors = Array('red','yellow','green','blue')

card_w = 212
card_h = 336

-- TODO: limit the number of draw cards
draw_card_count = 10


calcCardRect = function(card)
	local cx, cy, angle = card.x, card.y, math.rad(card.angle)
	local rotatePoint = function(x,y)
		local tempX = x - cx;
		local tempY = y - cy;
		-- now apply rotation
		local rotatedX = tempX*math.cos(angle) - tempY*math.sin(angle)
		local rotatedY = tempX*math.sin(angle) + tempY*math.cos(angle)
		-- translate back
		return {rotatedX + cy, rotatedY + cy}
	end
	
	local w2, h2 = card.width * card.scale / 2, card.height * card.scale / 2
	local ul, ur, dl, dr = 
		rotatePoint(cx - w2, cy - h2),
		rotatePoint(cx + w2, cy - h2),
		rotatePoint(cx - w2, cy + h2),
		rotatePoint(cx + w2, cy + h2)
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
		drawRect = function(self)
			Draw{
				{'color','white'},
				{'poly','fill',unpack(calcCardRect(self))}
			}
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