class AssetManager extends Editor {
	constructor (...args) {
		super(...args);
		var this_ref = this;

		this.setupDragbox();
		this.container.width = 400;
		this.container.height = 250;

		this.file_paths = {};
		this.file_elements = {};
		this.file_refresh_enabled = true;

		this.el_file_list = app.createElement("div","file-list");
		this.el_file_preview = app.createElement("div","file-preview");

		this.appendChild(this.el_file_list);
		this.appendChild(this.el_file_preview);

		this.refreshFileList();
		this.hideMenuButton();
		this.setTitle("Assets");

		document.addEventListener("fileChange", function(e){
			this_ref.refreshFileList();
		});
	}

	refreshFileList () {
		if (!this.file_refresh_enabled) return;

		let this_ref = this;

		app.clearElement(this.el_file_list);
		let walker = nwWALK.walk(app.project_path);
		this.file_paths = [];
		walker.on('file', function(path, stat, next){
			if (stat.isFile()) {
				let full_path = nwPATH.resolve(nwPATH.join(path, stat.name));
				this_ref.addFile(full_path);
			}
			next();
		});
	}

	addFile (path) {
		let this_ref = this;
		let file_type = app.findAssetType(path);

		if (file_type != 'other') {
			let el_file_row = app.createElement("div", "file-row");

			el_file_row.setAttribute('data-path',path);
			el_file_row.setAttribute('data-type',file_type);
			el_file_row.innerHTML = nwPATH.basename(path);
			el_file_row.addEventListener('click',function(ev){
				let el_files = app.getElements('.file-list > .file-row');
				for (let e = 0; e < el_files.length; e++) {
					el_files[e].classList.remove('selected');
				}
				ev.target.classList.add('selected');

				this_ref.previewFile(ev.target.dataset.path);
			});

			this.file_elements[path] = el_file_row;
			this.el_file_list.appendChild(el_file_row);
		}

		if (!this.file_paths[file_type])
			this.file_paths[file_type] = [];
		this.file_paths[file_type].push(path);
	}

	previewFile (path) {
		let this_ref = this;
		this.file_refresh_enabled = false;

		let file_type = app.findAssetType(path);

		app.clearElement(this.el_file_preview);

		// add file preview
		let el_preview_container = app.createElement('div','preview-container');
		if (file_type == 'image') {
			let el_image = app.createElement('img');
			el_image.onload = function() { el_preview_container.appendChild(el_image); }
			el_image.src = "file://"+path;
		} else {
			el_preview_container.style.display = "none";
		}

		// folder modifier
		let el_file_form = new BlankeForm([
			['filename', 'text'],
			['folder', 'text']
		]);

		let file_ext = nwPATH.extname(path);
		let file_folder = nwPATH.dirname(app.getRelativePath(path)).replace(/assets[/\\]/,'');
		let el_file = 

		el_file_form.setValue('filename', nwPATH.basename(path).replace(file_ext, ''));
		el_file_form.setValue('folder', file_folder);
		el_file_form.onChange('filename', function(value){
			blanke.cooldownFn('file_rename', 2000, function(){
				let new_path = nwPATH.resolve(nwPATH.join(app.project_path, 'assets', file_folder, value[0]+file_ext));

				// rename element
				this_ref.file_elements[path].innerHTML = value[0]+file_ext;
				this_ref.file_elements[new_path] = this_ref.file_elements[path];
				delete this_ref.file_elements[path];

				nwFS.rename(path, new_path);
				path = new_path;

			});
		});
		el_file_form.onChange('folder', function(value){
			blanke.cooldownFn('folder_rename', 2000, function(){
				let old_path = nwPATH.resolve(nwPATH.join(app.project_path, 'assets', file_folder, nwPATH.basename(path)));
				let new_path = nwPATH.resolve(nwPATH.join(app.project_path, 'assets', value[0], nwPATH.basename(path)));				

				try {
					nwFS.move(old_path, new_path, {overwrite:true},function(err){ // move file
						if (nwFS.readdirSync(nwPATH.dirname(old_path)).length == 0) {
							nwFS.removeSync(nwPATH.dirname(old_path));				// delete old folder if it's empty
						}
						file_folder = nwPATH.dirname(app.getRelativePath(new_path)).replace(/assets[/\\]/,'');

						// rename paths in other assets (not scripts however)
						if (this_ref.file_paths['script']) {
							for (let s of this_ref.file_paths['script']) {

							}
						}
						this.file_refresh_enabled = true;
					});

				} catch (e) {
					el_file_form.setValue('folder', file_folder);
					this.file_refresh_enabled = true;
				}
			});
		});

		this.el_file_preview.appendChild(el_preview_container);
		this.el_file_preview.appendChild(el_file_form.container);
	}
}

document.addEventListener("openProject", function(e){
	app.addSearchKey({
		key: 'View assets',
		onSelect: function() {
			if (!DragBox.focusDragBox("Assets"))
				new AssetManager(app);
		}
	});
});