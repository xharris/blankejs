BlankE.addEntity("CardCatalog")

function CardCatalog:init()
	self.cards = Group()
	self.img_button = Image("arrow")
	self.scroll_y = 0
	self:setSize(500, 200)
end

-- new_card: Card object
function CardCatalog:addCard(new_card)
	new_card:setSize("S")
	self.cards:add(new_card)
end

function CardCatalog:getCardsList()
	local ret_table = {}
	self.cards:forEach(function(c, card)
		table.insert(ret_table, card:getHash())	
	end)
	return ret_table
end

function CardCatalog:setSize(w,h)
	self.width = w - (w % 50) + self.img_button.width + 2
	self.height = h - (h % 50)
end

function CardCatalog:removeCardIndex(c)
	self.cards:remove(c)
end

function CardCatalog:clearCards()
	self.cards:clear()
end

function CardCatalog:draw()
	Draw.reset()
	Draw.setColor("black")
	
	local card_primary = Input("primary")
	local card_secondary = Input("secondary")
		
	-- scroll bar
	local width = self.width - self.img_button.width - 2
	local visibile_rows = self.height % 50
	local total_rows = self.cards:size() / math.floor(width / self.cards:size())
	function scrollUp()
		if self.scroll_y > 0 then
			self.scroll_y = self.scroll_y - 50
		end
	end
	function scrollDown()
		if self.y - self.scroll_y + (total_rows * 50) > self.y + self.height then
			self.scroll_y = self.scroll_y + 50
		end
	end
	
	-- UP Button
	self.img_button.x = self.x + self.width - self.img_button.width + 2
	self.img_button.y = self.y + self.img_button.height
	self.img_button.yscale = -1
	if self.scroll_y > 0 then
		self.img_button.alpha = 1
	else
		self.img_button.alpha = .25
	end
	self.img_button:draw()
	
	if card_primary.released and UI.mouseInside(self.img_button.x, self.img_button.y - self.img_button.height, self.img_button.width, self.img_button.height) then
		scrollUp()
	end
	
	-- DOWN Button
	self.img_button.x = self.x + self.width - self.img_button.width + 2
	self.img_button.y = self.y + self.height - self.img_button.height
	self.img_button.yscale = 1
	if self.y - self.scroll_y + (total_rows * 50) > self.y + self.height then
		self.img_button.alpha = 1
	else
		self.img_button.alpha = .25
	end
	self.img_button:draw()
	
	if card_primary.released and UI.mouseInside(self.img_button.x, self.img_button.y, self.img_button.width, self.img_button.height) then
		scrollDown()
	end
	
	local hover_rect = nil
	
	-- draw cards
	local cx, cy = self.x, self.y
	self.cards:forEach(function(c, card)
		card.x = cx
		card.y = cy - self.scroll_y
			
		if card.y > self.y - 2 and card.y < self.y + self.height then
			card:draw()
				
			if UI.mouseInside(card.x, card.y, card.width, card.height) then
				hover_rect = {card.x, card.y, card.width, card.height}
					
				if card_primary.released and self.onCardSelect then
					self:onCardSelect(card:getInfo(), c)
				end
					
				if card_secondary.released and self.onCardAction then
					self:onCardAction(card:getInfo(), c)	
				end
			end
		end

		cx = cx + card.width
		if cx > self.x + width - 2 then
			cx = self.x
			cy = cy + card.height
		end
	end)
	Draw.setColor("black")
	Draw.rect("line",self.x,self.y,width,self.height)
	
	if hover_rect then
		Draw.setColor("white")
		Draw.setLineWidth(2)
		Draw.rect("line", hover_rect[1], hover_rect[2], hover_rect[3], hover_rect[4])
	end

end