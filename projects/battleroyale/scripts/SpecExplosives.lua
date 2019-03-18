local grp_grenades = Group()
local grp_explosions = Group()
local spr_explosion = Sprite{image="quick_explosion", frames={"1-5",1,"1-5",2,"1-5",3,"1-5",4,"1-5",5,"1-5",6,"1-5",7,"1-5",8,"1-5",9,"1-5",10,"1-5",11,"1-5",12,"1-5",13,"1-5",14,"1-5",15,"1-5",16,"1-5",17,"1-5",18,"1-5",19,"1-5",20,"1-5",21,"1-5",22,"1-5",23,"1-5",24,"1-5",25,"1-5",26,"1-5",27,"1-5",28,"1-5",29,"1-5",30,"1-5",31,"1-5",32,"1-5",33}, frame_size={171,192}, speed=0.001, offset={0,0}}
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
			nade.direction = player.aim_direction
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
	self.rpt_explosion = Repeater(spr_explosion,{
		x = self.x, y = self.y,
		offset_x = {-50,50}, offset_y = {-50,50},
		duration = 0.5
	})
	self.rpt_explosion:emit(5)
	grp_explosions:add(self)
end
function Explosion:draw()
	self.rpt_explosion:draw()
	if self.rpt_explosion.count == 0 then
		self:destroy()
	end
end