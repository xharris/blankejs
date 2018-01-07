var nwGUI = require('nw.gui');
var nwFS = require('fs');
var nwWIN = nwGUI.Window.get();

var app = {
	current_folder: '',

	getElement: function(sel) {
		return document.querySelector(sel);
	},

	getElements: function(sel) {
		return document.querySelectorAll(sel);
	},

	close: function() {
		nwWIN.close();
	},

	open: function() {
		blanke.chooseFile("", function(file){
			app.current_file = file;
			nwFS.readFile(file, function(err, data){
				var load_data = JSON.parse(data);

			});
		});
	}
}

nwWIN.on('loaded', function() {
	nwWIN.showDevTools();

	new GameWindow(app);
	var main_code = new Code(app);
	main_code.edit("src/projects/test/game.js");
});