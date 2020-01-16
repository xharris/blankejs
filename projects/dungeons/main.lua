local rects = {}

Game{
	filter = "nearest",
	load = function()
		-- create random rects in circle
		function roundm(n, m) return math.floor(((n + m - 1)/m))*m end
		function getRandomPointInCircle(radius)
			local tile_size = 4
			local t = 2*math.pi*math.random()
			local u = math.random()+math.random()
			local r = nil
			if u > 1 then r = 2-u else r = u end 
			return roundm(radius*r*math.cos(t), tile_size), roundm(radius*r*math.sin(t), tile_size)
		end
		for r = 1,100 do
			local x, y = getRandomPointInCircle(30)
			local w, h = Math.random(32,64), Math.random(32,64)
			table.insert(rects, {
				x = x, y = y,
				w = w, h = h,
				points = {x - (w/2) + (Game.width/2), y - (h/2) + (Game.height/2), w, h}
			})
		end
		-- give each rect a body
		for _, rect in pairs(rects) do
			Physics.body('rect',{
					x = rect.x,
					y = rect.y,
					type = 'dynamic',
					fixedRotation = true,
					shapes = {
						{type='rect',width=rect.w,height=rect.h}
					}
			})
			rect.body = Physics.body('rect')
		end
	end,
	update = function(dt)
		for _, rect in pairs(rects) do
			local x, y = rect.body:getPosition()
			rect.points[1] = x
			rect.points[2] = y
		end 
	end,
	draw = function()
		for _, rect in pairs(rects) do 
			Draw{
				{'lineWidth',2},
				{'color','blue'},
				{'rect','fill',unpack(rect.points)},
				{'color','white'},
				{'rect','line',unpack(rect.points)}
			}
		end	
	end
}