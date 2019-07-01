let js_plugins = [];
let dir_plugins = [];
let zip_plugins = [];

let js_plugin_info = {};

let pathJoin;
let plugin_watch;

// get a list of .lua and .js files
function refreshPluginList(silent) {
	blanke.cooldownFn('refreshPlugin',500,function(){
		if (plugin_window)
			plugin_window.refreshList();
		inpectPlugins(silent)
	});
}

function movePlugin(path) {
	nwFS.ensureDir(pathJoin(app.settings.engine_path, 'plugins'), err => {
		if (err) return;
		for (let key in js_plugin_info) {
			nwFS.copySync()

		}
	})
}

// scan and copy plugins
function inspectPlugins(silent) {
	function inspectFile (file) {
		file = app.cleanPath(file);
		let info_key = file; // may be changed later, who knows
		
		if (file.endsWith('.js')) {
			// add file path
			let data = nwFS.readFileSync(file,'utf-8');
			if (!js_plugin_info[info_key]) {
				js_plugin_info[info_key] = {
					files: [],
				}
			}
			js_plugin_info[info_key].files.push(file);
			let info_keys = ['Name','Author','Description'];
			for (let k of info_keys) {
				let re = new RegExp(`\\*\\s*${k}\\s*:\\s*([\\w\\s\\.]+)`)
				//js_plugin_info
				let match = re.exec(data);
				if (match) js_plugin_info[info_key][k] = match[1];
			}
		}
		if (file.endsWith('.md')) {
			Docview.addPlugin(file.split('.')[0], pathJoin(app.settings.plugin_path,file.split('.')[0], file));
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
					movePlugin(full_path);
					//nwFS.copyFileSync(pathJoin(app.settings.plugin_path,f), pathJoin(eng_plugin_dir,f));
				}

				// .zip/.rar/.blex
				if (f.endsWith('.blex') || f.endsWith('.zip') || f.endsWith('.rar')) {
					let dir_path = pathJoin(app.settings.plugin_path,f.split('.')[0]);
					if (!nwFS.statSync(dir_path).isDirectory())
						nwZIP2(full_path).extractAllTo(dir_path, true);
					inspectFolder(dir_path);
					movePlugin(full_path);
				}

				// dir
				if (nwFS.statSync(full_path).isDirectory()) {
					d = nwPATH.basename(f);
					//nwFS.copySync(pathJoin(app.settings.plugin_path,d), pathJoin(eng_plugin_dir,d))
					inspectFolder(pathJoin(app.settings.plugin_path,d));
					movePlugin(full_path);
				}

				// if (!silent) blanke.toast("Plugins loaded!")
			}
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
	}

	refreshList () {

	}

	pluginOn () {

	}

	// _type: dir, js
	pluginOff (_type) {
		// remove file/dir
		switch (_type) {
			case 'dir':

				break;
			case 'js':
				
				break;
		}
	}
}

document.addEventListener("openProject",function(e){
	refreshPluginList(true);
});


document.addEventListener("ideReady",function(e){
	pathJoin = nwPATH.join;
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