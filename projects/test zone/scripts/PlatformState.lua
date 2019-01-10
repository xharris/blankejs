BlankE.addState("PlatformState");

local lvl, penguin, main_view, my_eff
	
function PlatformState:enter()
	PlatformState.background_color = "white"
	lvl = Scene("level1")
	
	penguin = Penguin()
	main_view = View(penguin)
	
	lvl:translate(game_width / 2, game_height / 2)
	lvl:addEntity("spawn",penguin)
	lvl:addTileHitbox("ground")
	
	Scene.dont_draw = {"spawn"}
	
	my_eff = Effect("static")
	--Debug.log(EffectManager.effects["chroma_shift"].string)
end

function PlatformState:update(dt)
	--lvl.angle = sinusoidal(-20,20,0.3)
	penguin.sprite_angle = lvl.angle
end

function PlatformState:draw()
	main_view:draw(function()
		--my_eff:draw(function()
			lvl:draw()
		--end)
		penguin:draw()
	end)
end