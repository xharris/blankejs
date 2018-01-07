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
		this.game_dragbox.appendContent(this.game_iframe);

		// refresh button
		this.btn_refresh = document.createElement("button");
		this.btn_refresh.classList.add("ui-button-sphere");
		this.btn_refresh.classList.add("btn-refresh");
		this.btn_refresh.innerHTML = "<i class=\"mdi mdi-refresh\"></i>";
		this.btn_refresh.obj_ref = this;
		this.btn_refresh.onclick = function(){ this.obj_ref.refresh(); };
		this.game_dragbox.appendContent(this.btn_refresh);
	}

	refresh () {
		this.game_iframe.src = this.game_iframe.src;
	}
}