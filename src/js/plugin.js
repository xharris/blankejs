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
		nwFS.readdir(app.settings.plugin_path, (err, files) => {
			let full_path;
			for (let f of files) {
				full_path = pathJoin(app.settings.plugin_path, f);
				if (f.endsWith('.js')) {
					js_plugins.push(f);
				}
				if (f.endsWith('.blex') || f.endsWith('.zip') || f.endsWith('.rar')) {
					zip_plugins.push(f);
				}
				if (nwFS.statSync(full_path).isDirectory()) {
					dir_plugins.push(full_path);
				}
			}
			inspectPlugins(silent);
		});
	});
}

function inspectPlugins(silent) {
	// move lua files to <engine_path>
	let eng_plugin_dir = app.settings.engine_path;

	function inspectFile (file) {
		file = app.cleanPath(file);
		console.log('inspect',file)
		if (file.endsWith('.js')) {
			let data = nwFS.readFileSync(file,'utf-8');
			js_plugin_info[file] = {
				path: file,
			}
			let info_keys = ['Name','Author','Description'];
			for (let k of info_keys) {
				let re = new RegExp()
				//js_plugin_info
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
		// .js
		for (let f of js_plugins) {
			inspectFile(pathJoin(app.settings.plugin_path,f))
			//nwFS.copyFileSync(pathJoin(app.settings.plugin_path,f), pathJoin(eng_plugin_dir,f));
		}
		// .zip/.rar/.blex
		for (let f of zip_plugins) {
			let dir_path = pathJoin(app.settings.plugin_path,f.split('.')[0]);
			if (!nwFS.statSync(dir_path).isDirectory())
				nwZIP2(pathJoin(app.settings.plugin_path,f)).extractAllTo(dir_path, true);
			inspectFolder(dir_path);
		}
		// dir
		for (let d of dir_plugins) {
			d = nwPATH.basename(d);
			//nwFS.copySync(pathJoin(app.settings.plugin_path,d), pathJoin(eng_plugin_dir,d))
			inspectFolder(pathJoin(app.settings.plugin_path,d))
		}

		// if (!silent) blanke.toast("Plugins loaded!")
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
	pluginOff (_type, ) {
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