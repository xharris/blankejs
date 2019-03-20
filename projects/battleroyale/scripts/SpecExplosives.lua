local grp_grenades = Group()
local grp_explosions = Group()
local spr_explosion = Sprite{image="quick_explosion", frames={"1-5","1-33"}, frame_size={171,192}, speed=5, offset={0,0}}
spr_explosion.xscale = 0.5
spr_explosion.yscale = 0.5
spr_explosion.xoffset = -spr_explosion.width / 2
spr_explosion.yoffset = -spr_explosion.height / 2

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
			nade:moveDirection(player.aim_direction, 1000)
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
	self.friction = 3
	self.timer = Timer(3):after(function()
		self:explode()	
	end):start()
	self:addShape("main","circle",{0,0,5})
	self.point = nil
end

function Grenade:update(dt)
	self.onCollision["main"] = function(other, sep)
		if other.tag == "ground" then
			self:collisionBounce()
		end
	end
end

function Grenade:explode()
	Explosion(self.x,self.y)
	self:destroy()
end

function Grenade:draw()
	Draw.setColor("gray")
	Draw.circle("fill",self.x,self.y,5)
	Draw.reset('color')
end

BlankE.addEntity("Explosion")
function Explosion:init(x,y)
	self.x, self.y = x, y
	local offset = 30
	self.rpt_explosion = Repeater(spr_explosion,{
		x = self.x, y = self.y,
		offset_x = {-offset,offset}, offset_y = {-offset,offset},
		duration = {0.5,1.5}
	})
	self.rpt_explosion:emit(10)
	grp_explosions:add(self)
end
function Explosion:draw()
	self.rpt_explosion:draw()
	if self.rpt_explosion.count == 0 then
		self:destroy()
	end
end