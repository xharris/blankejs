var nwGUI = require('nw.gui');
var nwFS = require('fs');
var nwPATH = require('path');
var nwWIN = nwGUI.Window.get();

var app = {
	project_path: "",
	watch: null,
	game_window: null,

	getElement: function(sel) {
		return document.querySelector(sel);
	},

	getElements: function(sel) {
		return document.querySelectorAll(sel);
	},

	close: function() {
		nwWIN.close();
	},

	open: function(path) {
		app.project_path = path

		// watch for file changes
		app.watch = nwFS.watch(app.project_path+'/scripts', function(evt_type, file) {
			if (file) {
				if (evt_type == 'rename') app.refreshScriptList();
			}
		});

		app.game_window = new GameWindow(app);
		app.refreshScriptList();
	},

	refreshScriptList: function() {
		var el_select = app.getElement("#script-list");
		el_select.innerHTML = "<option value=\"\" disabled selected style=\"display:none;\">Scripts</option>";

		var files = nwFS.readdirSync(app.project_path+"/scripts");
		for (var f = 0; f < files.length; f++) {
			var el_option = document.createElement("option");
			el_option.value=files[f];
			el_option.innerHTML=files[f];
			el_select.appendChild(el_option);
		}
	
	},

	addScript: function() {
		// create the file
		var script_count = nwFS.readdirSync(this.project_path+"/scripts").length;
		var script_path = this.project_path+"/scripts/script"+script_count.toString()+".js";
		nwFS.writeFileSync(script_path, "// code");
		app.refreshScriptList();

		// open the new script
		var main_code = new Code(app);
		main_code.edit(script_path);
	}
}

nwWIN.on('loaded', function() {
	nwWIN.showDevTools();

	// selecting script file
	app.getElement("#script-list").onchange = function() {
		var main_code = new Code(app);
		main_code.edit(app.project_path+"/scripts/"+this.value);
		app.getElement("#script-list").options[0].selected = true
	}

	app.open("src/projects/test");
});