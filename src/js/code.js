class Code extends Editor {
	constructor (...args) {
		super(...args);
		this.file = '';

		// create codemirror editor
		this.edit_box = document.createElement("textarea");
		this.edit_box.classList.add("code")
		this.appendChild(this.edit_box)

		var this_ref = this;
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
		this.codemirror.on('change', function(){
			this_ref.codemirror.refresh();
		});

		this.refreshScriptList();
	}

	edit (file_path) {
		var this_ref = this;

		this.file = file_path;
		var text = nwFS.readFileSync(file_path, 'utf-8');

		this.codemirror.setValue(text);
		this.codemirror.clearHistory();
		this_ref.codemirror.refresh();

		this.setTitle(nwPATH.basename(file_path));
	}

	save () {
		nwFS.writeFileSync(this.file, this.codemirror.getValue());
	}

	delete (name) {
		nwFS.unlink(nwPATH.dirname(this.file)+"/"+name);

		if (nwPATH.basename(this.file) == name) {
			this.file == '';
			this.refreshScriptList();
		}
	}

	deleteModal (name) {
		if (name == 'game.js') {
			blanke.showModal(
				"You cannot delete \'"+name+"\'",
			{
				"yes": function() {}
			});
		} else {
			var this_ref = this;
			blanke.showModal(
				"delete \'"+name+"\'",
			{
				"yes": function() { this_ref.delete(name); },
				"no": function() {}
			});
		}
	}

	rename (old_name, new_name) {
		nwFS.rename(nwPATH.dirname(this.file)+"/"+old_name, nwPATH.dirname(this.file)+"/"+new_name);
		this.file = nwPATH.dirname(this.file)+"/"+new_name;
		this.setTitle(nwPATH.basename(this.file));
	}

	renameModal (filename) {
		if (nwPATH.basename(filename) == 'game.js') {
			blanke.showModal(
				"You cannot rename \'"+nwPATH.basename(filename)+"\'",
			{
				"yes": function() {}
			});
		} else {
			var this_ref = this;
			blanke.showModal(
				"<label>new name: </label>"+
				"<input class='ui-input' id='new-file-name' style='width:100px;' value='"+nwPATH.basename(filename, nwPATH.extname(filename))+"'/>",
			{
				"yes": function() { this_ref.rename(filename, app.getElement('#new-file-name').value+".js"); },
				"no": function() {}
			});
		}
	}

	onFileChange (evt_type, file) {
		this.refreshScriptList();
	}

	onAssetSelect (value) {	
		this.save();
		this.edit(app.project_path+"/scripts/"+value);
	}

	refreshScriptList () {
		var this_ref = this;
		var files = nwFS.readdirSync(app.project_path+"/scripts");
		this.setAssetList(files, [
			{label: 'rename'},
			{label: 'delete'},
			{type: 'separator'},
			{label: 'add a script'}
		], function(label, asset) {
			if (label == 'rename') 
				this_ref.renameModal(asset);
			if (label == 'delete') 
				this_ref.deleteModal(asset);
			if (label == 'add a script')
				this_ref.addScript();
		});
		if (this.file == '') {
			this.edit(app.project_path+"/scripts/"+files[0]);
		}
	}

	addScript () {
		// create the file
		var script_count = nwFS.readdirSync(this.app.project_path+"/scripts").length;
		var script_path = this.app.project_path+"/scripts/script"+script_count.toString()+".js";
		nwFS.writeFileSync(script_path, "// code");
		app.refreshScriptList();
		// edit it
		this.edit(script_path);
	}
}