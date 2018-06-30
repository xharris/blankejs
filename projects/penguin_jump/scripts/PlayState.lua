BlankE.addState("PlayState")

local blocks = Group()

function PlayState:enter()
	Draw.setBackgroundColor('white')
	bob = IceBlock()
	
	blocks:add(bob)
	
end
