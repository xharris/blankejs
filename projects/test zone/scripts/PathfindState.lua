BlankE.addState("PathfindState")

local pathing = Pathfinder('space',15)
local sc_field, asteroids, player, alien
local off = 100
local points = {}

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
		
		pathing:addObstacle{'aster'..a, aster.x - 20, aster.y - 20, 40, 40}
	end
	
	for p = 1, #points, 2 do
		Debug.log(p/2 + .5,points[p],points[p+1])
	end
end

function PathfindState:update(dt)
	if asteroids then
		for a, aster in ipairs(asteroids) do
			aster.x = sinusoidal(aster.ix, aster.ix + off, 1.5, aster.rand)
			pathing:updateObstacle{'aster'..a, aster.x - 20, aster.y - 20, 40, 40}
			points = pathing:getPath(alien.x,alien.y,player.x,player.y)
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
		Draw.circle("line", aster.x, aster.y, 20)
	end
	Draw.setColor("orange")
	
	--Draw.setPointSize(1)
	Draw.line(unpack(points))
	for p = 1, #points/2 do
		Draw.text(p,points[2*p-1],points[2*p])
	end
	
	pathing:draw()
end