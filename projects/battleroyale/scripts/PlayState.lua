BlankE.addState("PlayState")

local player, sc_map
local vw_main = View("main")

Scene.tile_hitboxes = {"ground"}
Scene.hitboxes = {"ground"}
Scene.draw_order = {"ground"}

function PlayState:enter()
	self.background_color = "white"

	Net.join()
	Net.on('ready',function()
		sc_map = Scene("MapPlain")
			
		player = Player()
		player:setSpecialty("EXPLOSIVE")
		sc_map:addEntity("player_spawn",player)
			
		-- setup camera
		vw_main:follow(player)
	end)	
end

function PlayState:update(dt)

end

function PlayState:draw()
	vw_main:draw(function()
		sc_map:draw()
		Net.draw("Player")

		for name, spec in pairs(SPEC) do
			spec.draw()
		end
	end)
end