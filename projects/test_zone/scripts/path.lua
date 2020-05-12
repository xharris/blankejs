State("path",{
	enter = function()
		Map.config{
			tile_hitbox = { megman = 'ground' }	
		}
		local cam = Camera("main")
		
		local map = Map.load('platformer.map')
		local paths = map:getPaths("path_node")
		paths[1].debug = true
		
		local heart = Game.spawn("heart")
		cam.follow = heart
		
	paths[1]:go(heart, {target={tag='end'}})
	end,
})

Entity("heart", {
	images = { 'image2.png' },
	align = 'center',
	hitbox = true,
})