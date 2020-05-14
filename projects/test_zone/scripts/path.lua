State("path",{
	enter = function()
		Map.config{
			tile_hitbox = { megman = 'ground' }	
		}
		local cam = Camera("main")
		
		local map = Map.load('platformer.map')
		local paths = map:getPaths("path_node")
		paths[1].debug = true
		
		local heart = Game.spawn("heart", {x = 0})
		cam.follow = heart
		--[
		Hitbox.debug = true
		paths[1]:go(heart, {
			speed=50, 
			target={tag='end'}
		})
	end,
})

Entity("heart", {
	images = { 'image2.png' },
	align = 'center',
	hitbox = true,
})