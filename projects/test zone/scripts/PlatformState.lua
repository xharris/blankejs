BlankE.addState("PlatformState");

local lvl, penguin, main_view
	
function PlatformState:enter()
	lvl = Scene("level1")
	
	Penguin()
	penguin = Penguin.instances[1]
	main_view = View(penguin)
	
	lvl:translate(game_width / 2, game_height / 2)
	lvl:addEntity("spawn",penguin)
	lvl:addTileHitbox("ground")
end

function PlatformState:update(dt)
	lvl.angle = sinusoidal(-20,20,0.3)
	penguin.sprite_angle = lvl.angle
end

function PlatformState:draw()
	main_view:draw(function()
		lvl:draw()
	end)
end