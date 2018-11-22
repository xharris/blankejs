BlankE.addState("PlatformState");

local lvl
	
function PlatformState:enter()
	lvl = Scene("level1")
	lvl:addEntity("spawn",Penguin)
	lvl:addHitbox("ground")
end

function PlatformState:update(dt)

end

function PlatformState:draw()
	lvl:draw()
end
