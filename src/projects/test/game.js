var boss;

BlankE.init = function() {
  	boss = new Entity();
    boss.addSprite(
        name="stand",
        path="assets/boss.png"
    );
    boss.sprite_index = "stand";
}

BlankE.update = function(dt) {
 	boss.x += 0.2;
}