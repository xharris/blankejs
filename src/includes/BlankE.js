import 'phaser';

let game;
export function BlankE (config) {
	game = new Phaser.Game(config);
};

export class Scene extends Phaser.Scene {
	constructor() {
		super('Scene');
	}

	
}