BlankE.addState("PlayState")

local everything = Group()
local player


local eff_selected = Effect("crt")

function PlayState:enter()
	placeObjects()
	Draw.setBackgroundColor("brown")
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
	eff_selected.radius = (mouse_x / game_width) * 200
	eff_selected:draw(function()
		everything:call("draw")
	end)
end