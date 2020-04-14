State("ecs").on("enter", function

end)

var Bunny = Entity("Bunny",{
  vel: { x: 10 },
  image: { path:"bunny.bmp" }
  gravity: { v:10 }
		
}).on("add", function(dt) {
  this.pos.x = Game.width / 2;
  this.vel.x = Math.random(40, 150) * [-1,1].random();
			
})

System("Bunny")
	.template{	
	  vel: { x: 10 },
	  image: { path:"bunny.bmp" }
	  gravity: { v:10 }
	}
	.on("add", function(dt) {
	  this.pos.x = Game.width / 2;
	  this.vel.x = Math.random(40, 150) * [-1,1].random();
	})