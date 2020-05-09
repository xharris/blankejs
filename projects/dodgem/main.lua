local player

Image.animation("balls.png",{
	{ name="ball", rows=1, cols=5, speed=0 }
})
Image.animation("bluerobot.png",{
	{ name="robot_walk", rows=1, cols=8, frames={'2-7'}, speed=15 },
	{ name="robot_stand", rows=1, cols=8, frames={1} },
	{ name="robot_hit", rows=1, cols=8, frames={8} }
})

Input.set({
    left = { "left", "a", "dpleft" },
    right = { "right", "d", "dpright" },
	up = { "up", "w", "dpup" },
	down = { "down", "s", "dpdown" }
})

Audio('bomber_barbara.ogg', {name='main', looping=true, type='stream'})
Audio('snd_hit.wav', {name='hit', type='static'})

Game{
	background_color = "white",
	plugins = { 'xhh-effect', 'xhh-tween' },
	effect = {  'chroma shift', 'static' },
	load = function()	
		player = Player{x=Game.width/2, y=Game.height/2}
		
		local margin = 50
		
		Timer.every(1, function()
			Ball()
		end)
				
		--Audio.play('main')
		Audio.volume(0.05)
	end
}