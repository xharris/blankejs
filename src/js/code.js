class Code {
	constructor (app) {
		var workspace = app.getElement('#workspace');

		// create drag box
		this.game_dragbox = new DragBox('Code');
		this.game_dragbox.appendTo(workspace);
		this.game_dragbox.width = 300;
		this.game_dragbox.height = 250;

		// create codemirror editor
		this.edit_box = document.createElement("textarea");
		this.edit_box.classList.add("code")
		this.game_dragbox.appendChild(this.edit_box)
	}

	edit (file_path) {
		var this_ref = this;

		this.file = file_path;
		var text = nwFS.readFileSync(file_path, 'utf-8');

		this.codemirror = CodeMirror.fromTextArea(this.edit_box, {
			mode: "javascript",
			theme: "material",
            smartIndent : true,
            lineNumbers : true,
            lineWrapping : false,
            indentUnit : 4,
            extraKeys: {
            	"Ctrl-S": function(cm) {
            		this_ref.save();
            	}
            }
		});
		this.codemirror.setSize("100%", "100%");
		this.codemirror.setValue(text);
		this.codemirror.on('change', function(){
			this_ref.codemirror.refresh();
		});
	}

	save () {
		nwFS.writeFileSync(this.file, this.codemirror.getValue());
	}
}