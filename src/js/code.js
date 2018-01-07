class Code {
	constructor (app) {
		var workspace = app.getElement('#workspace');

		var width = 300;
		var height = 250;

		// create drag box
		this.game_dragbox = new DragBox('Code');
		this.game_dragbox.appendTo(workspace);
		this.game_dragbox.width = width;
		this.game_dragbox.height = height;
	}

	edit (file_path) {
		nwFS.readFile(file_path, function(err, data) {
			if (err) throw err;
			console.log(data);
		});
	}
}