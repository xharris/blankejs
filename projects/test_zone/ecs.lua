-- Hitbox.debug = true

local map
local heart_ecs

State('ecs',{
	enter = function()
		Input({
			right = { 'right', 'd' },
			left = { 'left', 'a' },
			up = { 'up', 'w' },
			down = { 'down', 's' },
			action = { 'space' }
		})
		
		for i = 1, 500 do -- 00 do 
			Heart()
		end
	end,
	draw = function()
		Draw{
			{'color','white'},
			{'line',Game.width/2,Game.height/2,mouse_x, mouse_y},
			{'fontSize',40},
			{'print',#World.get_type('heart_ecs'), 30, 30}
		}
	end
})

Heart = Entity("heart_ecs",{
	image = {
		path='image2.png', batch=false
	},
	align = 'center',
	hitbox = true,
	--gravity = { v=5 },
	effect = { 'static' },
	add = function(obj)
		obj.pos = {
			x = Math.random(0, Game.width),
			y = Math.random(0, Game.height)
		}
		obj.vel.x = Math.random(20,40)*table.random{-1,1}
		local scale = Math.random(0.5, 4.0)
		obj.effect.vars.static.strength = { 20, 0 }
	end,
	update = function(obj, dt)
		--obj.angle = Math.sinusoidal(-45,45,5)
		if Game.time > 1 then 
			obj.image.path = 'blue_robot.png'
		end
		if obj.pos.y > Game.height then 
			obj.vel.y = -Math.max(obj.vel.y,Game.height*1.2)
		end
		if obj.pos.x > Game.width or obj.pos.x < 0 then 
			obj.vel.x = -obj.vel.x
		end 
		obj.effect.enabled.static = obj.pos.x < Game.width /2
	end
})

local player_ecs = {
	animation = { 
		'blue_robot'
	},
	align='center',
	camera = { "player" },
	platforming = { gravity=10 },
	hitbox = true
}