card_names = Array('skip','draw','reverse','wild','wilddraw')
card_colors = Array('r','y','g','b')

-- TODO: limit the number of draw cards
draw_card_count = 10

Entity("Card",{
		name='', -- number / draw / skip / reverse
		value=0,
		color=nil,
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
			if self.color then
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
		}
})