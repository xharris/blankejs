let js_plugins = [];
let dir_plugins = [];
let zip_plugins = [];

let js_plugin_info = {};

let pathJoin;
let plugin_watch;

// get a list of .lua and .js files
function refreshPluginList(silent) {
	blanke.cooldownFn('refreshPlugin',500,function(){
		inspectPlugins(silent)
	});
}

// scan and copy plugins
function inspectPlugins(silent) {
	function inspectFile (file) {
		file = app.cleanPath(file);
		let info_key = (nwPATH.dirname(file) != app.settings.plugin_path) ? nwPATH.dirname(file) : file;
		
		if (file.endsWith('.js')) {
			if (!js_plugin_info[info_key]) {
				js_plugin_info[info_key] = {
					files: [],
					docs: [],
					enabled: false,
					module: null
				}
			}
			if (nwPATH.basename(file) == 'index.js') {
				// it's a module
				let module = js_plugin_info[info_key].module;
				if (module && module.onPluginUnload) {
					module.onPluginUnload();
					delete require.cache[file];
				}
				js_plugin_info[info_key].module = require(file);
				if (js_plugin_info[info_key].module.onPluginLoad)
					js_plugin_info[info_key].module.onPluginLoad();
				
				return;
			}

			let data = nwFS.readFileSync(file,'utf-8');

			// add file path
			if (!js_plugin_info[info_key].files.includes(file))
				js_plugin_info[info_key].files.push(file);

			let info_keys = ['Name','Author','Description'];
			for (let k of info_keys) {
				let re = new RegExp(`\\*\\s*${k}\\s*:\\s*([\\w\\s\\.]+)`)
				//js_plugin_info
				let match = re.exec(data);
				if (match) js_plugin_info[info_key][k.toLowerCase()] = match[1].trim();
			}
			if (!js_plugin_info[info_key].name)
				js_plugin_info[info_key].name = nwPATH.basename(file);

			// copy files if the plugin is already enabled
			if (js_plugin_info[info_key].enabled) {
				Plugins.enable(info_key);
			}
		}
		if (file.endsWith('.md')) {
			let data = nwFS.readFileSync(file,'utf-8');
			let info_keys = ['Name','Author'];
			let info = { Name:nwPATH.basename(file), Author:null };
			// get info about plugrin from readme
			for (let k of info_keys) {
				let re = new RegExp(`\\[\\/\\/\\]: # \\(${k}:\\s*([\\w\\s\\.]+)\\s*\\)`)
				let match = re.exec(data);
				if (match) info[k] = match[1].trim();
			}
			js_plugin_info[info_key].docs.push(file);
			Docview.addPlugin(info.Name+(info.Author ? ' ('+info.Author+')' : ''), file);
		}
	}

	function inspectFolder(folder) {
		let files = nwFS.readdirSync(folder);
		for (let f of files) {
			inspectFile(pathJoin(folder,f));
		}
	}

	nwFS.ensureDir(app.settings.plugin_path, err => {
		if (err) return console.error(err);
		
		nwFS.readdir(app.settings.plugin_path, (err, files) => {
			if (err) return;

			for (let f of files) {
				let full_path = pathJoin(app.settings.plugin_path,f);
				// .js
				if (f.endsWith('.js')) {
					inspectFile(full_path);
					//nwFS.copyFileSync(pathJoin(app.settings.plugin_path,f), pathJoin(eng_plugin_dir,f));
				}

				// .zip/.rar/.blex
				if (f.endsWith('.blex') || f.endsWith('.zip') || f.endsWith('.rar')) {
					let dir_path = pathJoin(app.settings.plugin_path,f.split('.')[0]);
					if (!nwFS.statSync(dir_path).isDirectory())
						nwZIP2(full_path).extractAllTo(dir_path, true);
					inspectFolder(dir_path);
				}

				// dir
				if (nwFS.statSync(full_path).isDirectory()) {
					d = nwPATH.basename(f);
					//nwFS.copySync(pathJoin(app.settings.plugin_path,d), pathJoin(eng_plugin_dir,d))
					inspectFolder(pathJoin(app.settings.plugin_path,d));
				}

				// if (!silent) blanke.toast("Plugins loaded!")
			}

			if (plugin_window) {
				plugin_window.refreshList();
			}
			dispatchEvent('loadedPlugins');
		})
	});

	// add .js files to ide somehow
	// ...
}

let plugin_window;
class Plugins extends Editor {
	constructor (...args) {
		super(...args);
		if (DragBox.focus("Plugins")) return;

		this.setupDragbox();
		this.setTitle("Plugins");
		this.removeHistory();
		this.hideMenuButton();

		this.container.width = 400;
		this.container.height = 370;	

		plugin_window = this;

		this.el_list_container = app.createElement("div","list-container");
		this.appendChild(this.el_list_container);

		this.el_reference = {};
		this.refreshList();
	}

	refreshList () {
		for (let key in js_plugin_info) {
			let info = js_plugin_info[key];
			// create the list item elements
			if (!this.el_reference[key]) {
				let el_ref = {};
				el_ref.el_toggle = app.createElement('label',['toggle','form-group']);
				el_ref.el_toggle.dataset.type = 'checkbox';
				el_ref.el_toggle.key_ref = key;
				el_ref.el_container = app.createElement('div',['container','dark']);
				el_ref.el_container.appendChild(el_ref.el_toggle);
				
				this.el_list_container.appendChild(el_ref.el_container);
				this.el_reference[key] = el_ref;
			}
		}
		// remove el references that are no longer a plugin
		for (let key in this.el_reference) {
			let exists = true;
			if (!js_plugin_info[key])
				exists = false;
			else {
				for (let f of js_plugin_info[key].files) {
					if (!nwFS.pathExistsSync(f))
						exists = false;
				}
			}
			if (!exists) {
				Plugins.disable(key);
				for (let doc of js_plugin_info[key].docs) {
					Docview.removePlugin(doc);
				}
				this.el_reference[key].el_container.remove();
				delete this.el_reference[key];
			}
		}
		// edit values of plugin elements
		for (let key in this.el_reference) {
			let el_ref = this.el_reference[key];
			let info = js_plugin_info[key];
			el_ref.el_toggle.innerHTML = `
				<div class='form-inputs'>
					<input type='checkbox' class='form-checkbox' ${info.enabled ? 'checked' : ''}/>
					<span class='checkmark'></span>
				</div>
				<div class='form-label'>
					<div class='name'>${info.name}</div>
					${info.author ? `<div class='author'>${info.author}</div>` : ''}
					${info.description ? `<div class='description'>${info.description}</div>` : ''}
				</label>
			`;
			el_ref.el_toggle.querySelector('.form-checkbox').addEventListener('change', e => {
				let key_ref = el_ref.el_toggle.key_ref;
				js_plugin_info[key_ref].enabled = e.target.checked;
				if (e.target.checked)
					Plugins.enable(key_ref);
				else 
					Plugins.disable(key_ref);
			});
		}
	}

	static getAutocomplete = () => {
		let ret = {};
		for (let p in js_plugin_info) {
			if (js_plugin_info[p].module && js_plugin_info[p].module.autocomplete)
				ret[p] = js_plugin_info[p].module.autocomplete;
		}
		return ret;
	}

	static enable (key) {
		nwFS.ensureDir(pathJoin(app.settings.engine_path, 'plugins'), err => {
			if (err) return;
			
			for (let path of js_plugin_info[key].files) {
				nwFS.copySync(path, pathJoin(app.settings.engine_path, 'plugins', nwPATH.basename(path)));
				app.project_settings.enabled_plugins[nwPATH.basename(path)] = true;
			}
			app.saveSettings();
		})
	}

	static disable (key) {
		// remove file		
		for (let path of js_plugin_info[key].files) {
			nwFS.removeSync(pathJoin(app.settings.engine_path, 'plugins', nwPATH.basename(path)));
			app.project_settings.enabled_plugins[nwPATH.basename(path)] = false;
		}
		app.saveSettings();
	}
}

document.addEventListener("openProject",function(e){
	if (!app.project_settings.enabled_plugins)
		app.project_settings.enabled_plugins = {};
	app.saveSettings();
	refreshPluginList(true);
});


document.addEventListener("ideReady",function(e){
	pathJoin = nwPATH.join;
	app.addSearchKey({
		key: 'Enable/disable plugins',
		onSelect: () => { new Plugins(); }
	})
});

document.addEventListener("appdataSave", (e) => {
	// watch for updates to plugins
	nwFS.ensureDir(app.settings.plugin_path, (err) => {
		if (plugin_watch) 
			plugin_watch.close();
		plugin_watch = nwWATCH(app.settings.plugin_path, {recursive: true}, function(evt_type, file) {
			refreshPluginList();
		});
	});
});