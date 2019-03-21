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
			
			if not player.net_event then 
				Net.event('spec.explosive.click',{
					_equipped_wpn=1,
					x=nade.x, y=nade.y,
					aim_direction=player.aim_direction,
					net_event=true
				})
			end
		end
	end,
	draw = function()
		grp_grenades:call('draw')
		grp_explosions:call('draw')
	end
}

Net.on('event',function(data)
	if data.event == 'spec.explosive.click' then
		SPEC.EXPLOSIVE.click(data.info)
	end
end)
	
BlankE.addEntity("Grenade")
function Grenade:init()
	self.friction = 3
	self.timer = Timer(3):after(function()
		self:explode()	
	end):start()
	self:addShape("main","circle",{0,0,5})
	self.point = nil
	
	grp_grenades:add(self)
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
function Explosion:init(x,y,duration)
	duration = duration or 2
	
	self.x, self.y = x, y
	local offset = 30
	self.rpt_explosion = Repeater(spr_explosion,{
		x = self.x, y = self.y,
		offset_x = {-offset,offset}, offset_y = {-offset,offset},
		duration = {0.5,math.min(1.5,duration)}
	})
	self.rpt_explosion.rate = 0.1
	self.rpt_explosion.emit_count = 10
	self:addShape("explosion","circle",{0,0,30})
	Timer(duration):after(function()
		self.rpt_explosion.rate = 0
		self:removeShape("explosion")	
	end):start()
	grp_explosions:add(self)
end
function Explosion:draw()
	self.rpt_explosion:draw()
	if self.rpt_explosion.count == 0 then
		self:destroy()
	end
	self:debugCollision()
end