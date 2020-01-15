local rects = {}

Game{
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
			Timer.after(r/10, function()
				local x, y = getRandomPointInCircle(30)
				local w, h = Math.random(32,64), Math.random(32,64)
				table.insert(rects, {x - (w/2) + (Game.width/2), y - (h/2) + (Game.height/2), w, h})
			end)
		end
	end,
	draw = function()
		for _, rect in pairs(rects) do 
			Draw{
				{'lineWidth',2},
				{'color','blue'},
				{'rect','fill',unpack(rect)},
				{'color','white'},
				{'rect','line',unpack(rect)}
			}
		end	
	end
}