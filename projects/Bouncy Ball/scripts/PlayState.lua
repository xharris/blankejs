BlankE.addState("PlayState")

-- declare some local variables that will hold our paddle and ball
local ent_paddle, ent_ball

function PlayState:enter()
	self.background_color = "white"
	ent_paddle = Paddle()	-- spawn the paddle
	ent_ball = Ball()		-- spawn a ball
	-- move the ball to the top-middle of the screen
	ent_ball.x = game_width / 2
	ent_ball.y = 0
	-- move the Paddle to the center of the screen
	ent_paddle.x = game_width / 2
	ent_paddle.y = game_height / 2
end

function PlayState:update(dt)
	
end

function PlayState:draw()
	-- draw the Paddle and Ball
	ent_paddle:draw()
	ent_ball:draw()
end
