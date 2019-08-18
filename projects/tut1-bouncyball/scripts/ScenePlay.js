Scene("ScenePlay",{
    onStart: function(scene) {
		Game.background_color = Draw.white2;
		scene.paddle = new Paddle();
		scene.ball = new Ball();
		scene.ball.x = Game.width / 2
		scene.ball.y = 50
		
		scene.paddle.x = Game.width / 2
		scene.paddle.y = Game.height / 2
		
		scene.paddle.debug = true;
		scene.ball.debug = true;
		
		scene.player_alive = true
		scene.score = 0;
		
		// spawn a missile every 5 seconds in a random spot
		Timer.every(5000, ()=>{
			if (scene.player_alive) {
				let rand_missile = new Missile()
				rand_missile.x = Util.rand_range(50, Game.width-50)
				rand_missile.y = Util.rand_range(50, Game.height-50)
			}
		});
		
		// every time the ball hits the paddle, increment the score
		scene.txt_score = new Text({
				fontSize:16,
				align:"center",
				x: 30,
				y: 30,
				text:"SCORE: 0"
			});
		Event.on('ball_bounce',()=>{
			scene.score += 1;
    		scene.txt_score.text = "SCORE: "+scene.score;
		});
		
        Event.on('paddle_explode',()=>{
			scene.player_alive = false;
			new Text({
				fontSize:16,
				align:"center",
				x: Game.width/2,
				y: Game.height/2,
				text:"Game Over"
			});
		});
    },
    onUpdate: function(scene, dt) {
		// end game if ball drops off screen
		if (scene.ball.y > Game.height) {
			scene.paddle.explode();	
		}
		// game is over. check if player wants to restart
		if (!scene.player_alive && Input("restart").released) {
			Scene.switch('ScenePlay')	
		}
    }
});
