BlankE.addEntity("Card")

local fnt_cardname = Font{
	image = "fnt_card",
	characters = " abcdefghijklmnopqrstuvwxyz" ..
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
    "123456789.,!?-+/():;%&`'*#=[]\"",
	size = 30
}

local header_mask = Mask("replace")
header_mask:setup("outside")

local small_art_mask = Mask("replace")
small_art_mask:setup("inside")

function Card:init()
	self.name = "Basic Bird"
	self.attribute = "bird"
	self.cost = 0
	self.description = "once per turn: cannot be fired"
	
	self.img_attr = Image("attr_bird")
	self.img_art = Image("Basic Bird")
	
	self.fnt_description = Font{
		size = 20
	}
	
	self:setSize('L')
end

function Card:update(dt)

end

--[[
	S - small and square, for card catalog
	L - large, all details
]]
function Card:setSize(new_size)
	self.size = new_size
	
	if self.size == 'S' then
		self.width = 50
		self.height = 50
		self.margin = 0
		
		self.img_art:setScale(1)
	end
	
	if self.size == 'L' then
		self.width = 262
		self.height = 150
		self.margin = 10
		
		self.img_art:setScale(2)
		self.fnt_description:set("limit",self.width - self.img_art.width - (self.margin*5))
	end
	
	self.scale = 1 
end

function Card:draw()
	local draw_x = self.x
	local draw_y = self.y

	-- fill
	Draw.setColor("grey")
	Draw.rect("fill",draw_x, draw_y, self.width, self.height)

	-- outline
	Draw.setColor("black")
	Draw.rect("line",draw_x, draw_y, self.width, self.height)
	
	-- SMALL CARD
	if self.size == "S" then
		
		-- art
		self.img_art.x = draw_x + (self.width / 2) - (self.img_art.width / 2) + 4
		self.img_art.y = draw_y + (self.height / 2) - (self.img_art.height / 4)
		self.img_art:draw()
		
		-- attribute
		self.img_attr.x = draw_x - 7
		self.img_attr.y = draw_y - 7
		self.img_attr.alpha = 0.5
		self.img_attr:draw()
		
		-- cost
		local txt_width = fnt_cardname:getWidth(self.cost)
		Draw.setColor("white")
		fnt_cardname:draw(self.cost, draw_x + self.width - txt_width - 5, draw_y + 2, {limit = txt_width, align = "center"})		

	end
	
	-- LARGE CARD
	if self.size == "L" then
	
		-- header fill
		local name_margin = 10
		local header_height = 18 + (name_margin*2)
		Draw.setColor("black")

		-- main art
		self.img_art.x = draw_x + (self.margin*2)
		self.img_art.y = (draw_y + self.height - ((self.height - header_height) / 2)) - (self.img_art.height / 2)
		self.img_art:draw()

		Draw.reset("color")
		header_mask.fn = function()
			Draw.circle("fill",	draw_x + self.width - self.margin - (header_height/2), draw_y + self.margin + (header_height / 2), header_height / 2)
		end

		Draw.setColor("white")
		Draw.setAlpha(.5)
		header_mask:draw(function()
			Draw.rect("fill",draw_x+self.margin,draw_y+self.margin,self.width-(self.margin*2) - (header_height/2),header_height)
		end)	
		Draw.circle("line",	draw_x + self.width - self.margin - (header_height/2), draw_y + self.margin + (header_height / 2), header_height / 2)

		-- name
		Draw.setColor("white")
		fnt_cardname:draw(self.name, draw_x + self.margin + name_margin, draw_y + self.margin + name_margin)

		-- attribute
		self.img_attr.x = draw_x + self.width - self.margin - header_height
		self.img_attr.y = draw_y + self.margin 
		self.img_attr:draw()

		-- cost 
		fnt_cardname:draw(self.cost,
			draw_x + self.width - self.margin - header_height + 1,
			draw_y + self.margin + (header_height / 2) + 10, {
				limit = header_height, 
				align = "center"
			}
		)

		-- description fill
		Draw.setColor("white")
		Draw.setAlpha(.5)
		local descr_y = self.y + header_height + (self.margin*2)
		local descr_x = draw_x + (self.margin*4) + self.img_art.width
		Draw.rect("fill",
			descr_x, descr_y,
			self.width - (self.margin) - (descr_x - self.x), self.height - header_height - (self.margin*3)
		)

		-- description
		Draw.setColor("black")
		self.fnt_description:draw(self.description, descr_x + self.margin, descr_y + self.margin)
		
	end
	
	Draw.reset("color")
end