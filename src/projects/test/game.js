var app, renderer;

function init() {
	app = new PIXI.Application({
		width: 512,
		height: 384,
	});
	document.body.appendChild(app.view);

	PIXI.loader.add(["assets/boss.png"]);

	PIXI.loader.load(function(){
		var boss = new PIXI.Sprite(PIXI.loader.resources["assets/boss.png"].texture);
		app.stage.addChild(boss);
	});
}