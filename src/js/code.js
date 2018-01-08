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

		// rename script button
		this.btn_rename = document.createElement("button");
		this.btn_rename.innerHTML = "<i class=\"mdi mdi-pencil\"></i>";
		this.btn_rename.classList.add("btn-rename");
		var this_ref = this;
		this.btn_rename.onclick = function() {
			this_ref.renameModal();
		}
		this.game_dragbox.appendChild(this.btn_rename);
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

		this.game_dragbox.setTitle(nwPATH.basename(file_path));
	}

	save () {
		nwFS.writeFileSync(this.file, this.codemirror.getValue());
	}

	rename (new_name) {
		nwFS.rename(this.file, nwPATH.dirname(this.file)+"/"+new_name);
		this.file = nwPATH.dirname(this.file)+"/"+new_name;
		this.game_dragbox.setTitle(nwPATH.basename(this.file));
	}

	renameModal () {
		var this_ref = this;
		blanke.showModal(
			"<label>new name: </label>"+
			"<input class='ui-input' id='new-file-name' style='width:100px;' value='"+nwPATH.basename(this_ref.file, nwPATH.extname(this_ref.file))+"'/>",
		{
			"yes": function() { this_ref.rename(app.getElement('#new-file-name').value+".js"); },
			"no": function() {}
		});
	}
}