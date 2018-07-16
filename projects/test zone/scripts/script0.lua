Input.set("move_left", "left", "a")
Input.set("move_right", "right", "d")
Input.set("move_up", "up", "w")
Input.set("move_down", "down", "s")

Input.set("select", "mouse.1")
Input["select"].can_repeat = false

BlankE.addState("StateOne")

function StateOne:enter()
	self.background_color = Draw.black
	
	self.player = Bob()
	self.player.color = Draw.red
	self.player.number = 1
	self.player.x = game_width /2
	self.player.y = game_height /2
end

function StateOne:update(dt)
	if Input("select") then
		State.transition("StateTwo", "circle-out")
	end
end

function StateOne:draw()
	self.player:draw()
end

BlankE.addState("StateTwo")

function StateTwo:enter()
	self.background_color = Draw.white
	
	self.player = Bob()
	self.player.color = Draw.green
	self.player.number = 2
	self.player.x = game_width /2
	self.player.y = game_height /2
end

function StateTwo:update(dt)
	if Input("select") then
		State.transition("StateOne", "circle-in")
	end
end


function StateTwo:draw()
	self.player:draw()
end

BlankE.addEntity("Bob")

function Bob:init()
	self.color = Draw.white
	self.number = 0
	Draw.setFontSize(18)
end

function Bob:draw()
	Draw.setColor(self.color)
	Draw.circle("fill", self.x, self.y, sinusoidal(100, 150, 1))
	Draw.setColor(Draw.invertColor(self.color))
	Draw.text(self.number, self.x, self.y)
end