function defineDragData(d_type, d_val) {
	return function(ev) {
		ev.dataTransfer.setData(d_type, d_val);
	}
}

class AssetManager extends Editor {
	constructor () {
		super();
		var this_ref = this;

		this.setupDragbox();
		this.removeHistory();
		this.container.width = 600;
		this.container.height = 320;

		this.categories = {};
		this.file_paths = {};
		this.file_elements = {};

		this.el_search = app.createElement("input","search");
		this.el_file_list = app.createElement("div","file-list");
		this.el_file_preview = app.createElement("div","file-preview");

		//this.appendChild(this.el_search);
		this.appendChild(this.el_file_list);
		this.appendChild(this.el_file_preview);

		this.refreshFileList();
		this.hideMenuButton();
		this.setTitle("Assets");

		document.addEventListener("fileChange", function(e){
			let ignore = ['config.json','dist\/'];
			for (let i of ignore) { 
				if (e.detail.file.match(i)) return;
			}
			this_ref.refreshFileList();
		});
	}

	refreshFileList () {
		let this_ref = this;
	    blanke.cooldownFn("asset-list-refresh",500,function(){
			let walker = nwWALK.walk(app.project_path);
			this_ref.file_paths = [];
			for (let cat in this_ref.categories) {
				let el_cat = this_ref.categories[cat];
				app.clearElement(el_cat.el_files);
				el_cat.el_count.innerHTML = 0;
			}

			// add files to the list
			let re_dist = /[\/\\]?dist[\/\\]/g;
			walker.on('file', function(path, stat, next){
				if (!path.match(re_dist) && stat.isFile()) {
					let full_path = nwPATH.resolve(nwPATH.join(path, stat.name));
					this_ref.addFile(full_path);
				}
				next();
			}); 
    	});
	}

	addCategory (name) {
		if (this.categories[name]) {
			let el_category = this.categories[name];

			blanke.sortChildren(el_category.el_files, function(a,b){
				if (a.innerHTML.toLowerCase() < b.innerHTML.toLowerCase()) return -1;
				if (a.innerHTML.toLowerCase() > b.innerHTML.toLowerCase()) return 1;
				return 0;
			});

			return;
		}

		let el_category = app.createElement("div",["category",name]);
		let el_cat_handle = app.createElement("div","cat-handle");
		let el_cat_title = app.createElement("div","cat-title");
		let el_cat_count = app.createElement("div","cat-count");
		let el_cat_files = app.createElement("div",["cat-files","hidden"]);

		el_cat_title.innerHTML = name;
		el_cat_count.innerHTML = 0;

		el_cat_handle.addEventListener('click',(e) => {
			el_cat_files.classList.toggle('hidden');
		});

		el_category.el_count = el_cat_count;
		el_category.el_files = el_cat_files;

		el_cat_handle.appendChild(el_cat_title);
		el_cat_handle.appendChild(el_cat_count);
		el_category.appendChild(el_cat_handle);
		el_category.appendChild(el_cat_files);

		this.categories[name] = el_category;
		this.el_file_list.appendChild(el_category);
	}

	addFile (path) {
		let this_ref = this;
		let file_type = app.findAssetType(path);

		if (file_type != 'other') {
			let el_file_row = app.createElement("div", "file-row");

			el_file_row.setAttribute('data-path',path);
			el_file_row.setAttribute('data-type',file_type);
			el_file_row.innerHTML = nwPATH.basename(path);
			el_file_row.draggable = true;
			el_file_row.ondragstart = defineDragData("text/plain", (path.match(/[\\\/\w]\/assets\/\w+\/(.*)\./,'')||['',path])[1] );

			el_file_row.addEventListener('click',function(ev){
				let el_files = app.getElements('.cat-files > .file-row');
				for (let e = 0; e < el_files.length; e++) {
					el_files[e].classList.remove('selected');
				}
				ev.target.classList.add('selected');

				this_ref.previewFile(ev.target.dataset.path);
			});

			this.file_elements[path] = el_file_row;
			let asset_type = app.findAssetType(path);
			this.addCategory(asset_type);
			let el_category = this.categories[asset_type];
			el_category.el_files.appendChild(el_file_row);
			el_category.el_count.innerHTML = el_category.el_files.childElementCount;
		}
		if (!Array.isArray(this.file_paths[file_type]))
			this.file_paths[file_type] = [];
		this.file_paths[file_type].push(path);
	}

	previewFile (path) {
		let this_ref = this;

		let file_type = app.findAssetType(path);

		app.clearElement(this.el_file_preview);

		// add file preview
		let el_preview_container = app.createElement('div','preview-container');
		if (file_type == 'image') {
			let el_image = app.createElement('img');
			el_image.setAttribute.draggable = true;
			el_image.ondragstart = defineDragData("text/plain", path);
			el_image.onload = function() { 
				let el_image_size = app.createElement("span");
				el_image_size.innerHTML = el_image.width + " x " + el_image.height;

				el_preview_container.appendChild(el_image);
				el_preview_container.appendChild(el_image_size);
			}
			el_image.src = "file://"+path;
		} 
		/*
		else if (file_type == 'audio') {

		}*/
		else {
			el_preview_container.style.display = "none";
		}

		// folder modifier
		let el_file_form = new BlankeForm([
			['filename', 'text'],
			['folder', 'text']
		]);
		el_file_form.container.classList.add("dark");

		let file_ext = nwPATH.extname(path);
		let file_folder = nwPATH.dirname(app.getRelativePath(path)).replace(/assets[/\\]/,'');

		el_file_form.setValue('filename', nwPATH.basename(path).replace(file_ext, ''));
		el_file_form.setValue('folder', file_folder);
		// TODO: does not work for scripts. come back to this later.
		let old_path = path;
		el_file_form.onChange('filename', function(value){
			blanke.cooldownFn('file_rename', 2000, function(){
				let new_path = nwPATH.resolve(nwPATH.join(app.project_path, 'assets', file_folder, value+file_ext));

				// rename element
				this_ref.file_elements[new_path] = this_ref.file_elements[old_path];
				this_ref.file_elements[new_path].innerHTML = value+file_ext;
				this_ref.file_elements[new_path].setAttribute('data-path',new_path);
				delete this_ref.file_elements[old_path];

				// rename file
				nwFS.rename(old_path, new_path);

				old_path = new_path;
				blanke.toast("Renamed file to \'"+value+file_ext+"\'");
			});
		});
		el_file_form.onChange('folder', function(value){
			blanke.cooldownFn('folder_rename', 2000, function(){
				let old_path = nwPATH.resolve(nwPATH.join(app.project_path, 'assets', file_folder, nwPATH.basename(path)));
				let new_path = nwPATH.resolve(nwPATH.join(app.project_path, 'assets', value, nwPATH.basename(path)));				

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
						blanke.toast("File moved to \'"+nwPATH.join(app.project_path, 'assets', value, nwPATH.basename(path))+"\'");
					});

				} catch (e) {
					el_file_form.setValue('folder', file_folder);
				}
			}, true);
		});

		// delete button
		let el_delete = app.createElement("button","ui-button-sphere");
		el_delete.innerHTML = `<object class="blanke-icon mdi-svg" data="icons/trash.svg" type="image/svg+xml"></object>`;
		el_delete.addEventListener("click",function(){
			blanke.showModal(
				"delete \'"+nwPATH.basename(old_path)+"\'?",
			{
				"yes": function() {
					nwFS.remove(old_path);
					app.clearElement(this_ref.el_file_preview);
					this_ref.refreshFileList();
				},
				"no": function() {}
			});
		});

		this.el_file_preview.appendChild(el_preview_container);
		this.el_file_preview.appendChild(el_file_form.container);
		this.el_file_preview.appendChild(el_delete);
	}
}

document.addEventListener("openProject", function(e){
	app.addSearchKey({
		key: 'View assets',
		onSelect: function() {
			if (!DragBox.focus("Assets"))
				new AssetManager(app);
		},
		group: 'Assetmanager',
		category: 'tools'
	});
});

document.addEventListener("closeProject", function(e){	
	app.removeSearchGroup("Assetmanager");
})