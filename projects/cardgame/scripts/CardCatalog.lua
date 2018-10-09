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

function CardCatalog:setSize(w,h)
	self.width = w - (w % 50) + self.img_button.width + 2
	self.height = h - (h % 50)
end

function CardCatalog:draw()
	Draw.setColor("black")
	
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
	
	-- draw up/down buttons
	self.img_button.x = self.x + self.width - self.img_button.width + 2
	self.img_button.y = self.y + self.img_button.height
	self.img_button.yscale = -1
	self.img_button:draw()
	
	if UI.button("btn_catalog_up", self.img_button.x, self.img_button.y - self.img_button.height, self.img_button.width, self.img_button.height) then
		scrollUp()
	end
	
	self.img_button.x = self.x + self.width - self.img_button.width + 2
	self.img_button.y = self.y + self.height - self.img_button.height
	self.img_button.yscale = 1
	self.img_button:draw()
	
	if UI.button("btn_catalog_down", self.img_button.x, self.img_button.y, self.img_button.width, self.img_button.height) then
		scrollDown()
	end
	
	-- draw cards
	local cx, cy = self.x, self.y
	self.cards:forEach(function(c, card)
		card.x = cx
		card.y = cy - self.scroll_y
		card.cost = c
			
		if card.y > self.y - 2 and card.y < self.y + self.height then
			card:draw()
		end

		cx = cx + card.width
		if cx > self.x + width - 2 then
			cx = self.x
			cy = cy + card.height
		end
	end)
	Draw.rect("line",self.x,self.y,width,self.height)
end