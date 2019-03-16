BlankE.addState("TweenState")

function TweenState:enter()
	Tween(0, 1, .5):play()
end

function TweenState:update(dt)

end

function TweenState:draw()

end
