local grp_grenades = Group()
local grp_explosions = Group()

SPEC.EXPLOSIVE = {
	init = function(player)
		player._equipped_wpn = 1
	end,
	action1 = function(player)
		player._equipped_wpn = 1
	end,
	click = function(player)
		if player._equipped_wpn == 1 then
			local nade = Grenade()
			nade.x = player.x
			nade.y = player.y 
			nade.direction = player.aim_direction
			Debug.log(player.aim_direction)
			grp_grenades:add(nade)
		end
	end,
	draw = function()
		grp_grenades:call('draw')
		grp_explosions:call('draw')
	end
}

BlankE.addEntity("Grenade")
function Grenade:init()
	self.speed = 1000
	self.friction = 3
	self.timer = Timer(3):after(function()
		self:explode()	
	end):start()
end

function Grenade:explode()
	grp_explosions(Explosion(self.x,self.y))
	self:destroy()
end

function Grenade:draw()
	Draw.setColor("gray")
	Draw.circle("fill",self.x,self.y,5)
end

BlankE.addEntity("Explosion")
function Explosion:init(x,y)
	self.x, self.y = x, y
end