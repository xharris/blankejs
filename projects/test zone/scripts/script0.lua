Input.set("select", "mouse.1")
Input["select"].can_repeat = false

BlankE.addState("StateOne")

main_font = Font({
	size = 50,
	align = "left"
})
Draw.setFont(main_font)

transition1 = "clockwise"
transition2 = "counter-clockwise"

function StateOne:enter()
	self.background_color = Draw.black
	
	Debug.log("bob")
	Debug.log("bob")
	Debug.log("bob")
	Debug.log("bob")
	Debug.log("bob")
	Debug.log(1,2,3,4,"sphagetti")
	Debug.log(unpack({"all",4,"of","them"}))
	
	self.player = Bob()
	self.player.color = Draw.red
	self.player.number = 1
	self.player.x = game_width /2
	self.player.y = game_height /2
end

function StateOne:update(dt)
	if Input("select") then
		State.transition("StateTwo", transition1)
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
		State.transition("StateOne", transition2)
	end
end


function StateTwo:draw()
	self.player:draw()
end

BlankE.addEntity("Bob")

function Bob:init()
	self.color = Draw.white
	self.number = 0
end

function Bob:draw()
	Draw.setColor(self.color)
	Draw.circle("fill", self.x, self.y, sinusoidal(100, 150, 1))
	Draw.setColor(Draw.invertColor(self.color))
	Draw.text(self.number, self.x, self.y)
end