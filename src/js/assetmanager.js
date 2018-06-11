class AssetManager extends Editor {
	constructor (...args) {
		super(...args);
		this.setupDragbox();
		this.container.width = 400;
		this.container.height = 250;

		this.el_file_list = app.createElement("div","file-list");
		this.el_file_preview = app.createElement("div","file-preview");

		this.appendChild(this.el_file_list);
		this.appendChild(this.el_file_preview);

		this.refreshFileList();
		this.hideMenuButton();
		this.setTitle("Assets");
		
		document.addEventListener("fileChange", function(e){
			// refreshFileList
		});
	}

	refreshFileList () {
		let this_ref = this;

		app.clearElement(this.el_file_list);
		let walker = nwWALK.walk(app.project_path);
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

			this.el_file_list.appendChild(el_file_row);
		}
	}

	previewFile (path) {
		let this_ref = this;
		let file_type = app.findAssetType(path);

		app.clearElement(this.el_file_preview);

		// add file preview
		let el_preview_container = app.createElement('div','preview-container');
		if (file_type == 'image') {
			let el_image = app.createElement('img');
			el_image.onload = function() { el_preview_container.appendChild(el_image); }
			el_image.src = path;
		}

		let file_ext = nwPATH.extname(path);

		// folder modifier
		let el_file_form = new BlankeForm([
			['filename', 'text'],
			['folder', 'text']
		]);

		//let file_ext
		el_file_form.setValue('filename', nwPATH.basename(path));
		el_file_form.setValue('folder', nwPATH.dirname(app.getRelativePath(path)));
		el_file_form.onChange('folder', function(value){
			
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