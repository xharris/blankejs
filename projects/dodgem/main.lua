Image.animation("balls.png",{
	{ name="ball", rows=1, cols=5, speed=0 }
})

Ball = Entity("Ball",{
	hitbox='circle',
	animations={ "ball" },
	align="center"
})

Player = Entity("Player",{
	
})

Game{
	load = function()
		Ball({x=Game.width/2, y=Game.height/2, anim_frame=3})
	end
}