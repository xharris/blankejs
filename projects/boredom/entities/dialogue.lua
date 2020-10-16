local dialogs = {}

Entity("Dialogue",{
	hitbox="trigger",
	collision=function(self, _, _, other_classname)
	  if other_classname == "Player" and not self.activated then
		self.activated = true
	  end
	end,
	activated=false
})

dialogs = {
  "Hi there",
  "Wow you're cool"
}