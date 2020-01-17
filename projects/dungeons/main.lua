local rects = {}
local rect_size_range = {16,64}
local SHAPES = 40
local tile_size = 4
local main_room_th_scale = 0.9
local triangles = nil

function roundm(n, m) return math.floor(((n + m - 1)/m))*m end
function getRandomPointInCircle(radius)
	local t = 2*math.pi*math.random()
	local u = math.random()+math.random()
	local r = nil
	if u > 1 then r = 2-u else r = u end 
	return roundm(radius*r*math.cos(t), tile_size), roundm(radius*r*math.sin(t), tile_size)
end
function getRandomPointInEllipse(ellipse_width, ellipse_height)
	local t = 2*math.pi*math.random()
	local u = math.random()+math.random()
	local r = nil
	if u > 1 then r = 2-u else r = u end
	return roundm(ellipse_width*r*math.cos(t)/2, tile_size), 
		   roundm(ellipse_height*r*math.sin(t)/2, tile_size)
end

local Delaunay = require "yonaba-delaunay"

Game{
	filter = "nearest",
	load = function()
		-- create random rects in circle
		for r = 1,SHAPES do
			local x, y = getRandomPointInEllipse(100,20)
			local w, h = Math.random(unpack(rect_size_range)), Math.random(unpack(rect_size_range))
			x = x - (w/2)
			y = y - (h/2)
			table.insert(rects, {
				x = x, y = y,
				w = w, h = h,
				points = {x, y, w, h}
			})
		end
		--Physics.world():translateOrigin(Game.width/2, Game.height/2)
		-- give each rect a body
		Timer.after(1,function()
			for _, rect in ipairs(rects) do
				Physics.body('rect',{
						x = rect.x,
						y = rect.y,
						type = 'dynamic',
						fixedRotation = true,
						shapes = {
							{type='rect',width=rect.w,height=rect.h,density=1}
						}
				})
				rect.body = Physics.body('rect')
			end
			-- pick main rooms
			local w_avg, h_avg = 0, 0
			for _, rect in ipairs(rects) do 
				w_avg, h_avg = w_avg + rect.w, h_avg + rect.h
			end
			w_avg, h_avg = w_avg / #rects, h_avg / #rects
			for _,rect in ipairs(rects) do
				if rect.w > w_avg*main_room_th_scale and rect.h > h_avg*main_room_th_scale then 
					rect.main_room = true
				end
			end
		end)
	end,
	update = function(dt)
		local awake_count = 0
		for _, rect in ipairs(rects) do
			if rect.body then
				local x, y = rect.body:getWorldCenter()
				rect.points[1] = x - (rect.points[3] / 2)
				rect.points[2] = y - (rect.points[4] / 2)
				if rect.body:isAwake() then 
					awake_count = awake_count + 1
				end
			end
		end
		if rects[1].body and awake_count == 0 and not triangles then
			print("triangulatin")
			local points = {}
			for i, rect in ipairs(rects) do 
				if rect.main_room then
					table.insert(points, Delaunay.Point(rect.points[1] + Game.width/2 + rect.w/2, rect.points[2] + Game.height/2 + rect.h/2))
				end
			end
			local temp = Delaunay.triangulate(unpack(points))
			triangles = {}
			for i, tri in ipairs(temp) do
				table.insert(triangles, {
					points = tri:isCW() and {tri.p1.x, tri.p1.y, tri.p2.x, tri.p2.y, tri.p3.x, tri.p3.y} or {tri.p3.x, tri.p3.y, tri.p2.x, tri.p2.y, tri.p1.x, tri.p1.y},
					
				})
			end
		end
	end,
	draw = function(d)
		Draw.translate(Game.width/2, Game.height/2)
		for i, rect in ipairs(rects) do	
			Draw{
				{'lineWidth',2},
				{'color', rect.main_room and 'red' or 'blue'},
				{'rect', 'fill', unpack(rect.points)},
				{'color','white'},
				{'rect', 'line', unpack(rect.points)},
				{'print', i, rect.points[1]+2, rect.points[2]}
			}
		end
		Draw.translate(-Game.width/2, -Game.height/2)	
		if triangles then 
			for i, tri in ipairs(triangles) do
				local pts = tri.points
				Draw{
					{'lineWidth',2},
					{'color', 'green'},
					{'line', 	pts[1], pts[2], pts[3], pts[4], 
								pts[3], pts[4], pts[5], pts[6], 
								pts[5], pts[6], pts[1], pts[2]}
				}
			end
		end
	end
}