class GameWindow {
	constructor (app) {
		var workspace = app.getElement('#workspace');

		var width = 512;
		var height = 384;

		this.game_window = document.createElement("div");
		this.game_window.classList.add("game-window");

		// add game content
		this.game_iframe = document.createElement("iframe");
		this.game_iframe.classList.add("game-iframe");
		this.game_iframe.width = width.toString();
		this.game_iframe.height = height.toString();
		this.game_iframe.frameborder = "0";
		this.game_iframe.scrolling = "no";
		this.game_iframe.src="projects/test/index.html";
		this.game_window.appendChild(this.game_iframe);

		// button container
		this.btn_container = document.createElement("div");
		this.btn_container.classList.add("ui-button-group");
		this.btn_container.classList.add("game-controls");

		// refresh button
		this.btn_refresh = document.createElement("button");
		this.btn_refresh.classList.add("ui-button-sphere");
		this.btn_refresh.classList.add("btn-refresh");
		this.btn_refresh.innerHTML = "<i class=\"mdi mdi-refresh\"></i>";
		this.btn_refresh.obj_ref = this;
		this.btn_refresh.onclick = function(){ this.obj_ref.refresh(); };
		this.btn_container.appendChild(this.btn_refresh);

		// pause/play button
		this.btn_pause = document.createElement("button");
		this.btn_pause.classList.add("ui-button-sphere");
		this.btn_pause.classList.add("btn-pause");
		this.btn_pause.innerHTML = "<i class=\"mdi mdi-pause\"></i><i class=\"mdi mdi-play\"></i>";
		this.btn_pause.obj_ref = this;
		this.btn_pause.onclick = function(){
			this.obj_ref.btn_pause.classList.toggle("paused");
			this.obj_ref.togglePause();
		};
		this.btn_container.appendChild(this.btn_pause);

		// resize button
		this.btn_resize = document.createElement("button");
		this.btn_resize.classList.add("ui-button-sphere");
		this.btn_resize.classList.add("btn-resize");
		this.btn_resize.innerHTML = "<i class=\"mdi mdi-arrow-top-left\"></i><i class=\"mdi mdi-arrow-bottom-right\"></i>";
		this.btn_resize.obj_ref = this;
		this.btn_resize.onclick = function(){
			this.obj_ref.btn_resize.classList.toggle("align-center");
			this.obj_ref.game_iframe.classList.toggle("align-center");
		};
		this.btn_container.appendChild(this.btn_resize);

		this.game_window.appendChild(this.btn_container);
		workspace.appendChild(this.game_window);
	}

	togglePause () {
		this.game_iframe.contentWindow.BlankE.pause = !(this.game_iframe.contentWindow.BlankE.pause);
	}

	refresh () {
		var this_ref = this;
		this.game_iframe.onload = function() {
			if (this_ref.btn_pause.classList.contains("paused")) {
				this_ref.togglePause();
			}
		}
		this.game_iframe.src = this.game_iframe.src;
	}
}