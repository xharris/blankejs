BlankE.addState("RepeaterState")

local img_dot, rpt_dots

function RepeaterState:enter()
	RepeaterState.background_color = "white"
	img_dot = Image("Basic Bird")
    rpt_dots = Repeater(img_dot, {
        x = game_width / 2, y = game_height / 2,
        direction = {45, 135}, speed = {3,6}
    })
	rpt_dots.rate = 0.01
end

function RepeaterState:update(dt)

end

function RepeaterState:draw()
	rpt_dots:draw()
end
