BlankE.addState("PlatformState");

local lvl, penguin
	
function PlatformState:enter()
	
	lvl = Scene("level1")
	
	penguin = Penguin()
	
	lvl:translate(game_width / 2, game_height / 2)
	lvl:addEntity("spawn",penguin)
	lvl:addHitbox("ground")
end

function PlatformState:update(dt)
	
end

function PlatformState:draw()
	lvl.draw_hitboxes = true
	lvl:draw()
end