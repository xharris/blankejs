let lua_plugins = [];
let js_plugins = [];

// get a list of .lua and .js files
function refreshPluginList() {
	nwFS.readdir(app.settings.plugin_path, (err, files) => {
		for (let f of files) {
			if (f.endsWith('.lua')) {
				lua_plugins.push(f);
			}
			if (f.endsWith('.js')) {
				js_plugins.push(f);
			}
		}
		installPlugins();
	});
}

function installPlugins() {
	// move lua files to <engine_path>/lua/blanke/plugins/
	let eng_plugin_dir = nwPATH.join(app.settings.engine_path,'lua','blanke','plugins');
	nwFS.emptyDir(eng_plugin_dir, err => {
		if (err) return console.error(err);
		for (let f of lua_plugins) {
			nwFS.copyFileSync(nwPATH.join(app.settings.plugin_path,f), nwPATH.join(eng_plugin_dir,f));
		}
	});

	// add .js files to ide somehow
	// ...
}

document.addEventListener("openProject",function(e){
	refreshPluginList();
});


document.addEventListener("ideReady",function(e){
	nwFS.ensureDir(app.settings.plugin_path, (err) => {
		let plugin_watch = nwFS.watch(app.settings.plugin_path, function(evt_type, file) {
			refreshPluginList();
		});
	});
});