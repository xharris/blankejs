class GameWindow {
	constructor (app) {
		var workspace = app.getElement('#workspace');

		var width = 512;
		var height = 384;

		// create drag box
		this.game_dragbox = new DragBox('Game');
		this.game_dragbox.appendTo(workspace);
		this.game_dragbox.width = width + 7;
		this.game_dragbox.height = height + 36;

		// add game content
		this.game_iframe = document.createElement("iframe");
		this.game_iframe.width = width.toString();
		this.game_iframe.height = height.toString();
		this.game_iframe.frameborder = "0";
		this.game_iframe.scrolling = "no";
		this.game_iframe.src="projects/test/index.html";
		this.game_dragbox.setContent(this.game_iframe);
	}
}