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
let temp_plugin_info = {};
function inspectPlugins(silent) {
	function inspectFile (file) {
		file = app.cleanPath(file);
		let info_key = nwPATH.relative(app.ideSetting("plugin_path"), nwPATH.dirname(file));
		let info_keys = ['Name','Author','Description','ID','Enabled'];
		
		if (!temp_plugin_info[info_key]) {
			temp_plugin_info[info_key] = {
				files: [],
				docs: [],
				enabled: true,
				module: null,
				id:'',
				classes: []
			}
		}

		if (nwPATH.basename(file) == 'index.js') {
			// it's a module
			let module = temp_plugin_info[info_key].module;
			let module_path = file;
			if (!nwPATH.isAbsolute(file))
				module_path = nwPATH.join(nwPATH.relative(app.ideSetting("plugin_path"), ''), file);
			module_path = require.resolve(module_path);
			
			if (module) {
				if (module.onPluginUnload) 
					module.onPluginUnload();
				delete require.cache[module_path];
			}

			temp_plugin_info[info_key].module = require(module_path);
			if (temp_plugin_info[info_key].module.onPluginLoad)
				temp_plugin_info[info_key].module.onPluginLoad();
			
			module = temp_plugin_info[info_key].module;	
			if (module.info) {
				for (let k of info_keys) {
					if (k == 'Enabled')
						temp_plugin_info[info_key].enabled = module.info.enabled;
					else
						temp_plugin_info[info_key][k.toLowerCase()] = module.info[k.toLowerCase()];
				}
				if (Array.isArray(module.info.classes)) 
					temp_plugin_info[info_key].classes = module.info.classes;
			}
			return;
		}

		if (engine.file_ext.some(f => file.endsWith(f))) {
			let data = nwFS.readFileSync(file,'utf-8');

			// add file path
			if (!temp_plugin_info[info_key].files.includes(file))
				temp_plugin_info[info_key].files.push(file);

			for (let k of info_keys) {
				let re = new RegExp(engine.plugin_info_key(k))
				//js_plugin_info
				let match = re.exec(data);
				if (match) {
					if (k == 'Enabled')
						temp_plugin_info[info_key].enabled = match[1].trim();
					else
						temp_plugin_info[info_key][k.toLowerCase()] = match[1].trim();
				}
			}
			if (!temp_plugin_info[info_key].name)
				temp_plugin_info[info_key].name = nwPATH.basename(file);
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
			temp_plugin_info[info_key].docs.push(file);
			if (temp_plugin_info[info_key].enabled)
				Docview.addPlugin(info.Name+(info.Author ? ' ('+info.Author+')' : ''), file);
			else
				Docview.removePlugin(file);
		}
	}

	function inspectFolder(folder) {
		let files = nwFS.readdirSync(folder);
		for (let f of files) {
			inspectFile(pathJoin(folder,f));
		}
	}

	nwFS.ensureDir(app.ideSetting("plugin_path"), err => {
		if (err) return console.error(err);
		
		nwFS.readdir(app.ideSetting("plugin_path"), (err, files) => {
			if (err) return;

			Plugins.clearPlugins();
			for (let f of files) {
				let full_path = pathJoin(app.ideSetting("plugin_path"),f);
				// .js
				if (engine.file_ext.some(_f => f.endsWith(_f))) {
					inspectFile(full_path);
					//nwFS.copyFileSync(pathJoin(app.ideSetting("plugin_path"),f), pathJoin(eng_plugin_dir,f));
				}

				// .zip/.rar/.blex
				if (f.endsWith('.blex') || f.endsWith('.zip') || f.endsWith('.rar')) {
					let dir_path = pathJoin(app.ideSetting("plugin_path"),f.split('.')[0]);
					if (!nwFS.statSync(dir_path).isDirectory())
						nwZIP2(full_path).extractAllTo(dir_path, true);
					inspectFolder(dir_path);
				}

				// dir
				if (nwFS.statSync(full_path).isDirectory()) {
					d = nwPATH.basename(f);
					//nwFS.copySync(pathJoin(app.ideSetting("plugin_path"),d), pathJoin(eng_plugin_dir,d))
					inspectFolder(pathJoin(app.ideSetting("plugin_path"),d));
				}

				// if (!silent) blanke.toast("Plugins loaded!")
			}

			// check which plugins are valid
			for (let key in temp_plugin_info) {
				let info = temp_plugin_info[key];
				if (info.id) {
					if (info.enabled !== false) {
						js_plugin_info[info.id] = info;
					} else {
						// disabled and remove docs
						for (let file of info.docs) {
							Docview.removePlugin(file);
						}
					}
				}
			}

			if (plugin_window) {
				plugin_window.refreshList();
			}

			// copy files if the plugin is already enabled
			if (app.projSetting("enabled_plugins")) {
				for (let id in js_plugin_info) {
					if (app.projSetting("enabled_plugins")[id] == true) {
						Plugins.enable(id);
					} else {
						Plugins.disable(id);
					}
				}
			}

			app.sanitizeURLs();
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
			if (!js_plugin_info[key] || js_plugin_info[key].enabled == false)
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
					<input type='checkbox' class='form-checkbox' ${app.projSetting("enabled_plugins")[info.id] == true ? 'checked' : ''}/>
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
		// already enabled plugins
		for (let key in app.projSetting("enabled_plugins")) {
			if (app.projSetting("enabled_plugins")[key] == true) {
				Plugins.enable(key);
			} else
				Plugins.disable(key);
		}
	}

	static getAutocomplete = () => {
		let ret = {};
		for (let p in js_plugin_info) {
			let info = js_plugin_info[p];
			if (info.module && info.enabled && info.module.autocomplete)
				ret[p] = info.module.autocomplete;
		}
		return ret;
	}

	static enable (key) {
		nwFS.ensureDir(pathJoin(app.ideSetting("engine_path"), 'plugins'))
		
		if (js_plugin_info[key]) {
			for (let path of js_plugin_info[key].files) {
				nwFS.copySync(path, pathJoin(app.ideSetting("engine_path"), 'plugins', key, nwPATH.basename(path)));
			}
			app.projSetting("enabled_plugins")[key] = true;
			dispatchEvent('pluginChanged',{ key: key, info: js_plugin_info[key] });
			app.saveSettings();
		}
	}

	static disable (key) {
		if (!js_plugin_info[key]) return;
		// remove file		
		for (let path of js_plugin_info[key].files) {
			nwFS.removeSync(pathJoin(app.ideSetting("engine_path"), 'plugins', key, nwPATH.basename(path)));
		}
		app.projSetting("enabled_plugins")[key] = false;
		dispatchEvent('pluginChanged',{ key: key, info: js_plugin_info[key] });
		app.saveSettings();
	}

	static getClassNames () {
		let classnames = [];
		for (let p in js_plugin_info) {
			let info = js_plugin_info[p];
			if (info.enabled)
				classnames = classnames.concat(info.classes);
		}
		return classnames;
	}

	static clearPlugins() {
		nwFS.emptyDirSync(pathJoin(app.ideSetting("engine_path"), 'plugins'));
	}
}

document.addEventListener("openProject",function(e){
	if (!app.projSetting("enabled_plugins"))
		app.projSetting("enabled_plugins",{})
	app.saveSettings();
	refreshPluginList(true);
});

document.addEventListener("closeProject",function(e){
	Plugins.clearPlugins();
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
	nwFS.ensureDir(app.ideSetting("plugin_path"), (err) => {
		if (plugin_watch) 
			plugin_watch.close();
		plugin_watch = app.watch(app.ideSetting("plugin_path"), function(evt_type, file) {
			refreshPluginList();
		});
	});
});