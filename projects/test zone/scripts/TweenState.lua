BlankE.addState("TweenState")

local bob, rpt_bob
function TweenState:enter()
	bob = Sprite{image="sprite-example", frames={"1-3",1}, frame_size={29,43}, speed=0.1, offset={12,8}}
	rpt_bob = Repeater(bob)
	rpt_bob.rate = 0.1
	rpt_bob.spr_frame = 1
	--rpt_bob.emit_count = 10
	--rpt_bob.spr_speed = .1
	--rpt_bob.offset_x = {-10,10}
	--rpt_bob.offset_y = {-10,10}
end

function TweenState:update(dt)
	bob.x, bob.y = mouse_x, mouse_y
	rpt_bob.x, rpt_bob.y = bob.x, bob.y
end

function TweenState:draw()
	rpt_bob:draw()
	bob:draw()
end
