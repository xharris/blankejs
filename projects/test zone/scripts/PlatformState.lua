BlankE.addState("PlatformState");

local lvl, penguin, main_view, my_eff
	
function PlatformState:enter()
	PlatformState.background_color = "white"
	lvl = Scene("level1")
	
	penguin = Mario()
	main_view = View("main")
	main_view:follow(penguin)
	
	lvl:translate(game_width / 2, game_height / 2)
	lvl:addEntity("spawn",penguin)
	lvl:addTileHitbox("ground")
	
	Scene.dont_draw = {"spawn"}
end

function PlatformState:update(dt)
	--lvl.angle = sinusoidal(-20,20,0.3)
	penguin.sprite_angle = lvl.angle
end

function PlatformState:draw()
	main_view:draw(function()
		lvl:draw()
		penguin:draw()
	end)
end