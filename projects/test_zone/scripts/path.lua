State("path",{
	enter = function()
		Map.config{
			tile_hitbox = { megman = 'ground' }	
		}
		local cam = Camera("main")
		bob = CameraMan()
		
		local map = Map.load('platformer.map')
		local paths = map:getPaths("path_node")
		paths[1].debug = true
		
		local heart = Game.spawn("heart", {x = 0})
		cam.follow = heart
		--[
		Hitbox.debug = true
		paths[1]:go(heart, {
			speed=10, 
			target={tag='end'}
		})
		
		Input.set({
			action = { "n" }
		})
	end
})

Entity("heart", {
	images = { 'image2.png' },
	align = 'center',
	hitbox = true,
})
