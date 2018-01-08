var nwGUI = require('nw.gui');
var nwFS = require('fs');
var nwPATH = require('path');
var nwWIN = nwGUI.Window.get();

var app = {
	project_path: "",
	watch: null,
	game_window: null,
	maximized: false,

	getElement: function(sel) {
		return document.querySelector(sel);
	},

	getElements: function(sel) {
		return document.querySelectorAll(sel);
	},

	createElement: function(el_type, el_class) {
		var ret_el = document.createElement(el_type);
		ret_el.classList.add(el_class);
		return ret_el;
	},

	close: function() {
		nwWIN.close();
	},

	maximize: function() {
		if (app.maximized) nwWIN.unmaximize();
		else nwWIN.maximize();
		app.maximized = !app.maximized;
	},

	minimize: function() {
		nwWIN.minimize();
	},

	open: function(path) {
		app.project_path = path

		// watch for file changes
		app.watch = nwFS.watch(app.project_path, function(evt_type, file) {
			if (file) { dispatchEvent("fileChange", {type:evt_type, file:file}); }
		});

		app.game_window = new GameWindow(app);
	},
}

nwWIN.on('loaded', function() {
	nwWIN.showDevTools();

	/* selecting script file
	app.getElement("#script-list").onchange = function() {
		app.code.edit(app.project_path+"/scripts/"+this.value);
		app.getElement("#script-list").options[0].selected = true
	}*/

	app.open("src/projects/test");
});