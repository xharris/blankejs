BlankE.addEntity("DisplayCard")

local fnt_cardname = Font{
	image = "fnt_card",
	characters = " abcdefghijklmnopqrstuvwxyz" ..
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
    "123456789.,!?-+/():;%&`'*#=[]\"",
	size = 30
}

local header_mask = Mask("replace")
header_mask:setup("outside")

function DisplayCard:init()
	self:setSize('L')
	
	self.name = "Basic Bird"
	self.attribute = "bird"
	self.cost = 0
	self.decription = "once per turn: cannot be fired"
	
	self.img_attr = Image("attr_bird")
	self.img_art = Image("Basic Bird")
end

function DisplayCard:update(dt)

end

--[[
	S - small, for card catalog
	L - large, all details
]]
function DisplayCard:setSize(new_size)
	self.size = new_size
	local w, h = 240, 336
	local scale = 1
	
	if self.size == 'S' then
		scale = 1/4
	end
	
	if self.size == 'L' then
		scale = 1
	end
	
	self.width = w * scale
	self.height = h * scale
	self.margin = 10 * scale
end

function DisplayCard:draw()
	-- fill
	Draw.setColor("grey")
	Draw.rect("fill",self.x, self.y, self.width, self.height)
	
	-- outline
	Draw.setColor("black")
	Draw.rect("line",self.x, self.y, self.width, self.height)
		
	-- header fill
	local name_margin = 10
	local header_height = 18 + (name_margin*2)
	Draw.setColor("black")

	-- main art
	self.img_art.x = self.x + self.margin 
	self.img_art.y = self.y + self.margin + header_height
	self.img_art:draw()
	
	Draw.reset("color")
	header_mask.fn = function()
		Draw.circle("fill",	self.x + self.width - self.margin - (header_height/2), self.y + self.margin + (header_height / 2), header_height / 2)
	end
	
	Draw.setColor("white")
	Draw.setAlpha(.5)
	header_mask:draw(function()
		Draw.rect("fill",self.x+self.margin,self.y+self.margin,self.width-(self.margin*2) - (header_height/2),header_height)
	end)	
	Draw.circle("line",	self.x + self.width - self.margin - (header_height/2), self.y + self.margin + (header_height / 2), header_height / 2)

	-- name
	Draw.setColor("white")
	fnt_cardname:draw(self.name, self.x + self.margin + name_margin, self.y + self.margin + name_margin)
	
	-- attribute
	self.img_attr.x = self.x + self.width - self.margin - header_height
	self.img_attr.y = self.y + self.margin 
	self.img_attr:draw()
	
	-- cost 
	fnt_cardname:draw(self.cost,
		self.x + self.width - self.margin - header_height + 1,
		self.y + self.margin + (header_height / 2) + 10, {
			limit = header_height, 
			align = "center"
		}
	)
	
	-- description
	Draw.setColor("white")
	Draw.setAlpha(.5)
	local descr_y = self.img_art.y + self.img_art.height
	Draw.rect("fill", self.x + self.margin, descr_y, self.width - (self.margin*2), self.height - self.img_art.height - (self.margin*2))
end