BlankE.addState("PlayState")

-- declare some local variables that will hold our paddle, ball, score, and game status
local ent_paddle, ent_ball, score, game_over

function PlayState:enter()
	self.background_color = "white"
	ent_paddle = Paddle()	-- spawn the paddle
	ent_ball = Ball()		-- spawn a ball
	-- move the ball to the top-middle of the screen
	ent_ball.x = game_width / 2
	ent_ball.y = 50
	-- move the Paddle to the center of the screen
	ent_paddle.x = game_width / 2
	ent_paddle.y = game_height / 2
	
	-- spawn a missile every 5 seconds in a random spot
	Timer.every(8, function()
		local rand_missile = Missile()
		rand_missile.x = randRange(50, game_width - 50)
		rand_missile.y = randRange(50, game_height - 50)
	end)
	
	-- set the score to 0
	score = 0
	
	-- every time the ball hits the paddle, increment the score
	Signal.on("ball_hit_paddle",function()
		score = score + 1
	end)
	
	game_over = false
	-- end game if paddle explodes
	Signal.on("paddle_explode", function()
		game_over = true	
	end)
end

function PlayState:update(dt)
	-- end game if ball drops
	if ent_ball.y > game_height then
		ent_ball:destroy()
		ent_paddle:explode()
	end
	
	-- if the game is over, check if the player wants to restart
	if game_over and Input("restart").released then
		State.switch("PlayState")
	end
end

function PlayState:draw()
	-- draw the Paddle and Ball
	ent_paddle:draw()
	ent_ball:draw()
	-- draw missiles
	Missile.instances:call('draw')
	-- draw the score
	Draw.setColor("black")
	Draw.text("SCORE: "..tostring(score), 20, 20)
	
	-- draw game over text
	if game_over then
		Draw.text("GAME OVER", 0, game_height/2, {align="center"})
	end
end
