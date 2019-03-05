BlankE.addState("PathfindState")

local sc_field, asteroids, player, alien
local off = 100

function PathfindState:enter()
	PathfindState.background_color = "black"
	sc_field = Scene("asteroid_field")
	
	player = sc_field:getObjects("player")["layer0"][1]
	alien = sc_field:getObjects("alien")["layer0"][1]
	asteroids = sc_field:getObjects("asteroid")["layer0"]
	
	for a, aster in ipairs(asteroids) do
		aster.ix = aster.x
		aster.iy = aster.y
		aster.rand = randRange(0,100)/100
	end
end

function PathfindState:update(dt)
	if asteroids then
		for a, aster in ipairs(asteroids) do
			aster.x = sinusoidal(aster.ix, aster.ix + off, 1.5, aster.rand)
			--aster.y = sinusoidal(aster.iy - off, aster.iy + off, 0.5, aster.iy + aster.rand)
		end
	end
end

function PathfindState:draw()
	Draw.setColor("blue")
	Draw.circle("fill", player.x, player.y, 10)
	
	Draw.setColor("green")
	Draw.circle("fill", alien.x, alien.y, 10)
	
	for a, aster in ipairs(asteroids) do
		Draw.setColor("red")
		Draw.circle("fill", aster.x, aster.y, 20)
		Draw.setColor("white")
		Draw.text(aster.rand,aster.x, aster.y)
	end
	
end