local points, projection
local rotationZ, rotationX, rotationY
local angle = 0

local connect = function(a, b, projected)
	Draw.lineWidth(1)
	Draw.line(projected[a].x, projected[a].y, projected[b].x, projected[b].y)
end 

State("math",{
	enter = function()
		points = Array(
			Vector(-0.5,	-0.5,	-0.5),
			Vector(0.5, 	-0.5,	-0.5),
			Vector(0.5, 	0.5,	-0.5),
			Vector(-0.5, 	0.5,	-0.5),
				
			Vector(-0.5,	-0.5,	0.5),
			Vector(0.5, 	-0.5,	0.5),
			Vector(0.5, 	0.5,	0.5),
			Vector(-0.5, 	0.5,	0.5)
		)
		projection = {
			{1, 0, 0},
			{0, 1, 0},
			{0, 0, 1}
		}
	end,
	update = function(dt)
		angle = angle + math.rad(1)
		
	end,
	draw = function()
		Draw.color('white')
		Draw.print(Window.full_os, 50, 50)
			
		--angle = 45
		rotationZ = {
			{ Math.cos(angle), -Math.sin(angle), 0 },
			{ Math.sin(angle), Math.cos(angle), 0 },
			{ 0, 0, 1 }
		}
			
		rotationX = {
			{ 1, 0, 0 },
			{ 0, Math.cos(angle), -Math.sin(angle)},
			{ 0, Math.sin(angle), Math.cos(angle)}
		}
			
		rotationY = {
			{ Math.cos(angle), 0, -Math.sin(angle)},
			{ 0, 1, 0 },
			{ Math.sin(angle), 0, Math.cos(angle)}
		}
			
		local projected = Array()
		Draw.translate(Game.width/2, Game.height/2)
		points:forEach(function(v)		
			-- perform transformations
			
			local rotated = matmul(rotationX, v);
			rotated = matmul(rotationZ, rotated);
			rotated = matmul(rotationZ, rotated);
					
			-- perspective conversion
			local dist = 2
			local z = 1 / (dist - rotated.z)
			projection = {
				{ z, 0, 0 },
				{ 0, z, 0 }
			}
					
			local projected2d = matmul(projection, rotated)
			projected2d:mult(300)
			
			-- draw the point
			Draw.pointSize(5)
			Draw.circle('fill',projected2d.x, projected2d.y,3)
			
			projected:push(projected2d)
		end)
			
		-- draw the edges
		for i = 1, 4 do
			connect(i, i % 4 + 1, projected)
			connect(i + 4, i % 4 + 5, projected)
			connect(i, i + 4, projected)
		end 
	end
})