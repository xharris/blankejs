BlankE.addState("PlayState")

local everything = Group()
local player

function PlayState:enter()
	placeObjects()
end

function placeObjects()	
	everything:forEach(function(o, obj)
		obj:destroy()	
	end)
	for n = 0, 20 do
		everything:add(Npc())
	end
	
	player = Hacker()
	everything:add(player)
end

function PlayState:update(dt)
	everything:sort("y")
end

function PlayState:draw()
	everything:call("draw")
end