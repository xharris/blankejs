local dialogs = {}

Entity("Dialogue",{
	hitbox=true,
	reaction="cross",
	collision=function(self, info)
		if info.other.tag == "Player" and not self.activated then
			self.activated = true
			print(self.map_tag)
		end
	end,
	activated=false
})

dialogs = {
	"Hi there",
	"Wow you're cool"
}