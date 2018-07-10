BlankE.addClassType("menuState", "State")

ent_igloo = nil

function menuState:enter(previous)
	self.background_color = Draw.black
	ent_igloo = Igloo(previous == 'playState')
end

function menuState:update(dt)

end

function menuState:draw()
	ent_igloo:draw()
end