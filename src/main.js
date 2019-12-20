/*

C - completed
T - completed but needs more testing

TODO:
C	separate tabs from history bar
C	implement fibonnaci-sized windows
C	sprite sheet preview: should display image dimensions
C	find and replace
C	GamePreview - auto insert Asset.add() method
	Add confirm dialog when closing changed Code		

BUGS:
- 	mapeditor: should only place tile on map if the mouse started inside the canvas on mouse down
C 	sceneeditor: pointerup event after pointerdown event happens outside of window --> freeze
T	sceneeditor: create new scene, remove premade layers, rename layer -> other layers come back
C 	sceneeditor: image search keys still remain after closing scene editor
C	sceneeditor: re-opening opens 3 instances
*/
const elec = require('electron');

var nwFS = require('fs-extra');
var nwWALK = require('walk');
var nwPATH = require('path');
var nwOS = require('os');
const { spawn, execFile, exec } = require('child_process')
const { cwd, env, platform } = require('process')
var nwNOOB = require('./js/server.js');
var nwZIP = require('archiver'); // used for zipping
var nwZIP2 = require('adm-zip'); // used for unzipping
var nwWATCH = require('node-watch');
var nwREQ = require('request');
var nwUGLY = require('uglify-es');
var nwUTIL = require('util');
var nwDEL = require('del');
var nwCLONE = require('lodash.clonedeep');
var nwMD = require('markdown-it')();

let re_engine_classes = /classes\s+=\s+{\s*([\w\s,]+)\s*}/;

const DEFAULT_IDE_SETTINGS = {
	recent_files:[],
	plugin_path:'plugins',
	engine_path:'love2d',
	themes_path:'themes',
	autocomplete_path:'./autocomplete.js',
	theme:'green',
	quick_access_size:5,
	game_preview_enabled:true,
	autoreload_external_run:false,
	run_save_code:true
};

const DEFAULT_PROJECT_SETTINGS =  {
	ico:nwPATH.join('src','logo.ico'),
	icns:nwPATH.join('src','logo.icns'),
	game_size:3,
	window_size:3,
	quick_access:[],
	autoplay_preview:true
};

var app = {
	project_path: "",
	proj_watch: null,
	asset_watch: null,
	maximized: false,
	os: null, // win, mac, linux,
	error_occured: null,
	ignore_errors: false,
	
	get window() {
		return elec.remote.getCurrentWindow()
	},

	getElement: function(sel) {
		return document.querySelector(sel);
	},

	getElements: function(sel) {
		return document.querySelectorAll(sel);
	},

	createElement: function(el_type, el_class) {
		var ret_el = document.createElement(el_type);
		if (Array.isArray(el_class)) ret_el.classList.add(...el_class);
		else if (el_class != undefined) ret_el.classList.add(el_class);
		return ret_el;
	},

	createIconButton: function(icon, title) {
		return blanke.createIconButton(icon, title);
	},

	clearElement: function(element) {
		while (element.firstChild) {
			element.removeChild(element.firstChild);
		}
	},

	setBadgeNum: function(id, num) {
		if (num > 0) {
			app.getElement(id).innerHTML = num;
		} else {
			app.getElement(id).innerHTML = '';
		}
	},

	contextMenu: function(x, y, items) {
		var menu = new elec.remote.Menu();
		for (var i = 0; i < items.length; i++) {
			var menuitem = menu.append(new elec.remote.MenuItem(items[i]));
		}
		menu.popup({x:x, y:y});
	},

	close: function() {
		app.window.close();
	},

	maximize: function() {
		if (app.maximized) app.window.unmaximize();
		else app.window.maximize();
		app.maximized = !app.maximized;
	},

	minimize: function() {
		app.window.minimize();
	},
	watch: function(path, cb) {
		return nwWATCH(path, {
			recursive: true,
			filter: f => !/dist/.test(f) && !f.includes('.asar')
		}, cb);
	},
	getRelativePath: function(path) {
		return nwPATH.relative(app.project_path,path);
	},

	refreshWordCloud: function() {

	},

	newProject: function(path) {
		nwFS.mkdir(path, function(err) {
			if (!err) {
				// copy template files
				nwFS.copySync(nwPATH.join(cwd(),'src','template'), path);
				app.hideWelcomeScreen();
				app.openProject(path);
			}
		});
	},

	newProjectDialog: function() {
		blanke.chooseFile({
			properties:['openDirectory']
		}, function(file_path){
			blanke.showModal(
				"<label style='line-height:35px'>new project name:</label></br>"+
				"<label>"+file_path+nwPATH.sep+"</label>"+
				"<input class='ui-input' id='new-proj-name' style='width:100px;' value='my_project'/>",
			{
				"yes": function() { app.newProject(nwPATH.join(file_path, app.getElement('#new-proj-name').value)); },
				"no": function() {}
			});
		});
	},

	win_title: '',
	setWinTitle: function(title) {
		app.win_title = title;
		app.getElement("#search-input").placeholder = title;
	},
	themes: {},
	theme_data: {},
	setTheme: function(name) {
		// get theme variables from file
		nwFS.readFile(nwPATH.join(app.ideSetting("themes_path"),name+'.json'),'utf-8',(err, data)=>{
			if (err) return;
			let theme_data = JSON.parse(data);
			app.theme_data = theme_data;
			// change theme variables
			less.modifyVars(theme_data);
			app.ideSetting("theme",name)
			app.saveAppData();
			app.refreshThemeList();
			dispatchEvent("themeChanged");
		});
	},
	getThemeColor: name => parseInt(app.theme_data[name].replace('#','0x'),16),
	refreshThemeList: function() {
		// get list of themes available
		nwFS.ensureDirSync(app.ideSetting("themes_path"));
		app.themes = nwFS.readdirSync(app.ideSetting("themes_path")).map((v)=>v.replace('.json',''));
	},
	closeProject: function() {
		// app.saveSettings();
		app.getElement("#search-container").classList.add("no-project");
		if (app.isServerRunning()) 
			app.stopServer();

		app.clearElement(app.getElement("#recents-container"))
		dispatchEvent("closeProject", {path: app.project_path});
		app.project_path = '';
		Editor.closeAll();
		app.clearHistory();
		app.showWelcomeScreen();
		app.setWinTitle("BlankE");
	},

	isProjectOpen: function() {
		return (app.project_path && app.project_path != "");
	},
	openProject: function(path) {
		// validate: only open if there's a main.lua
		nwFS.readdir(path, 'utf8', function(err, files){
			if (!err) { // && files.includes('main.lua')) { // TODO add project validation
				if (app.isProjectOpen())
					app.closeProject();

				app.project_path = path;

				// watch for file changes
				app.proj_watch = app.watch(app.project_path, function(evt_type, file) {
					if (evt_type == 'remove')
						app.removeQuickAccess(nwPATH.basename(file));
					if (file) { dispatchEvent("fileChange", {type:evt_type, file:file}); }
				});

				// watch for asset changes
				app.getAssets();
				if (app.asset_watch)
					app.asset_watch.close()
				
				let asset_path = app.getAssetPath();
				nwFS.ensureDirSync(asset_path)
				app.asset_watch = app.watch(asset_path, (evt_type, file) => {
					if (file) { 
						blanke.cooldownFn('asset_watch',500,()=>{
							app.getAssets((files)=>{
								dispatchEvent("assetsChange");
							});
						})
					}
				});
				
				// add to recent files
				app.last_quick_access = '';
				app.ideSetting("recent_files",app.ideSetting("recent_files").filter(e => !e.includes(nwPATH.basename(path))))
				app.ideSetting("recent_files").unshift(path);
				app.saveAppData();

				app.getElement("#search-container").classList.remove("no-project");
				app.setWinTitle(nwPATH.basename(app.project_path));

				// start first scene
				app.loadSettings(() => {
					app.hideWelcomeScreen();
					dispatchEvent("openProject", {path: path});
				});
			} else {
				blanke.toast(`Could not open project '${nwPATH.basename(path)}'`);
				app.closeProject();
			}
		});
 
	},

	openProjectDialog: function() {
		blanke.chooseFile({
			properties:['openDirectory']
		}, function(file_path){
			app.openProject(file_path);
		});
	},

	refreshGameSource: function () {
		if (app.game) app.game.refreshSource();
	},

	autocomplete: {},
	autocomplete_loaded: false,
	refreshAutocomplete: function() {
		let err = false;
		app.autocomplete_loaded = false;
		app.ignore_errors = true;
		try {
			let data = app.require(app.ideSetting("autocomplete_path"))
			if (!data)
				throw 'autocomplete not loaded';
			else 
				app.autocomplete = data;
		} catch (e) {
			err = true;
			blanke.toast('error in autocomplete file!')
			console.log(e);
		} finally {
			app.ignore_errors = false;
			if (!err) {
				app.autocomplete_loaded = false;
				console.log('autocomplete loaded');
			}
		}
	},
	autocomplete_toast: null,
	watchAutocomplete: function() {
        app.refreshAutocomplete();
		if (autocomplete_watch) {
            autocomplete_watch.close();
            dispatchEvent("autocompleteChanged");
        }
		app.ignore_errors = true;
	    autocomplete_watch = nwFS.watch(nwPATH.resolve('src',app.ideSetting("autocomplete_path")), function(e){
            app.refreshAutocomplete();
			dispatchEvent("autocompleteChanged");
			if (!app.autocomplete_toast)
				app.autocomplete_toast = blanke.toast("autocomplete reloaded!", null, () => {
					app.autocomplete_toast = null;
				});
		});
		app.ignore_errors = false;
	},
	engine_code: '',
	minifyEngine: function(cb, opt) {
		if (!engine.minifyEngine) return;
		
		opt = opt || {};
		blanke.cooldownFn('minify-engine',500,function(){
			app.getElement("#status-icons > .engine-status").classList.add('active');
			let cb_done = (...args) => {
				if (cb) cb(...args);
				blanke.cooldownFn('engine-status-off',1000,function(){
					app.getElement("#status-icons > .engine-status").classList.remove('active');
				},true);
				dispatchEvent('engineChange');
			}
			let cb_err = () => {
				if (!opt.silent) {
					let toast = blanke.toast("Engine compilation failed",-1);
					toast.icon = 'close';
					toast.style = "bad";
				}
			}
			if (engine.minifyEngine)
				engine.minifyEngine(cb_err, cb_done, opt);
		}, true);
	},

	extra_windows: [],
	play: function(options) { 
        if (app.isProjectOpen() && engine.play) {
			if (app.ideSetting('run_save_code'))
				Code.saveAll();
			engine.play(options);
		}
	},

	notify: function (opt) {
		let notif = new elec.remote.Notification(opt.title, opt);
		notif.onclick = opt.onclick;
		notif.show();
	},

	newWindow: function (html, options, cb) {
		if (!cb) {
			cb = options;
			options = {};
		}
		options.parent = app.window;
		let child = new elec.remote.BrowserWindow(options);
		child.loadFile(nwPATH.relative('',html));
		app.extra_windows.push(child);
		if (cb) cb(child);
	},

	toggleWindowVis: function() {
		DragBox.showHideAll();
	},

	toggleSplit: function() {
		FibWindow.toggleSplit();
		app.getElement("#btn-winsplit").title = "toggle window splitting "+(split_enabled == true ? '(ON)' : '(OFF)');
	},

	isServerRunning: function() {
		return (nwNOOB.address != null);
	},

	runServer: function() {
		nwNOOB.setLogFunction(function () {
			console.log.apply(console, arguments)
		});
		nwNOOB.onPopulationChange = function(population) {
			if (population <= 0) {
				population = 0;
				app.getElement("#status-icons > .server-status").classList.remove('active');
			} else {
				app.getElement("#status-icons > .server-status").classList.add('active');
			}
			app.getElement('#status-icons > .server-status > .server-pop').innerHTML = population;
			// app.getElement
		}
		if (nwNOOB.address) {
			blanke.toast('server already running on '+nwNOOB.address);
		} else {
			nwNOOB.start(function(address){
				blanke.toast('server started on '+address);
				app.getElement('#status-icons > .server-status > .server-pop').innerHTML = '0';
			});
		}
	},

	stopServer: function() {
		nwNOOB.stop(function(success){
			if (success) {
				blanke.toast('server stopped');
				app.getElement('#status-icons > .server-status > .server-pop').innerHTML = 'x';
			} else
				blanke.toast('server not running');
		});
	},

	search_funcs: {},
	search_args: {},
	search_hashvals: [],
	search_group: {},
	search_hash_category: {},
	search_titles: {},
	hashSearchVal: function(key, tags) {
		tags = tags || [];
		tags.push('?')
		return key + '=' + tags.join('+');
	},
	unhashSearchVal: function(hash_val) {
		return {
			key: hash_val.split('=')[0],
			tags: hash_val.split('=')[1].split('+'),
		}
	},
	// options: text, description, onSelect, tags
	addSearchKey: function(options) {
		var hash_val = app.hashSearchVal(options.key, options.tags);
		app.search_funcs[hash_val] = options.onSelect;
		app.search_args[hash_val] = options.args;
		app.search_hash_category[hash_val] = options.category ? options.category.toLowerCase() : null;
		app.search_titles[hash_val] = options.key;

		if (!app.search_hashvals.includes(hash_val))
			app.search_hashvals.push(hash_val);
		if (options.group) {
			if (!app.search_group[options.group]) app.search_group[options.group] = [];
			app.search_group[options.group].push(hash_val);
		}
		// quick access pending
		if (app.pending_quick_access.includes(options.key)) {
			app.refreshQuickAccess(options.key);
			app.pending_quick_access = app.pending_quick_access.filter(p => p != options.key);
		}
	},
	isSearchKey: function(hash) {
		return (hash in app.search_funcs);
	},
	triggerSearchKey: function(hash_val) {
		if (!app.search_funcs[hash_val]) return;
		app.search_funcs[hash_val].apply(this, app.search_args[hash_val]);
		var el_search = app.getElement("#search-input")
		el_search.value = "";
		el_search.blur();
		app.clearElement(app.getElement("#search-results"));

		// move found value up in list
		app.search_hashvals = app.search_hashvals.filter(e => e != hash_val);
		app.search_hashvals.unshift(hash_val);
		app.refreshQuickAccess(hash_val);
	},
	getSearchCategory: function(hash_val) {
		return app.search_hash_category[hash_val];
	},
	removeSearchGroup: function(group) {
		if (app.search_group[group]) {
			var group_len = app.search_group[group].length;
			for (var v = 0; v < group_len; v++) {
				app.removeSearchHash(app.search_group[group][v]);
			}
			app.search_group[group] = [];
		}
	},

	removeSearchKey: function(key, tags) {
		var hash_val = app.hashSearchVal(key, tags);
		app.removeSearchHash(hash_val);
		app.removeQuickAccess(hash_val);
	},

	removeSearchHash: function(hash) {
		app.search_hashvals = app.search_hashvals.filter(e => e != hash);
		app.search_funcs[hash] = null;
		app.search_args[hash] = null;
	},
	
	// returns an array containing .result elements
	getSearchResults: function() {
		let ret_array = [];
		let getChildren = function(el_parent) {
			Array.from(el_parent.children).forEach(function(e){
				if (e.is_category) {
					getChildren(e.el_children, ret_array);
				} else {
					ret_array.push(e);
				}
			});
		}
		getChildren(app.getElement("#search-results"), []);
		return ret_array;
	},

	settings: {},
	getAppDataFolder: function(){
		let path = nwPATH.join(elec.remote.app.getPath("appData"), "BlankE"); 
		nwFS.ensureDirSync(path);
		return path;
	},
	loadAppData: function(callback) {
		var app_data_folder = app.getAppDataFolder();
		var app_data_path = nwPATH.join(app_data_folder, 'blanke.json');
		nwFS.readFile(app_data_path, 'utf-8', function(err, data){
			if (!err && data.length > 1) 
				app.settings = JSON.parse(data);
				
			app.settings = Object.assign(DEFAULT_IDE_SETTINGS, app.settings || {});
			if (callback) callback();
		});
	},

	require: (path) => {
		delete require.cache[require.resolve(path)];
		return require(path);
	},

	plugin_watch:null,
	saveAppData: function() {
		var app_data_folder = app.getAppDataFolder();
		var app_data_path = nwPATH.join(app_data_folder, 'blanke.json');
		
		nwFS.stat(app_data_folder, function(err, stat) {
			if (!stat.isDirectory()) nwFS.mkdirSync(app_data_folder);
			nwFS.writeFile(app_data_path, JSON.stringify(app.settings));
		});

		dispatchEvent('appdataSave');
	},

	ideSetting: function (k, v) {
		if (v != null) {
			app.settings[k] = v;
			// app.saveAppData();
		}
		if (!k) return app.settings;
		return app.settings[k] || DEFAULT_IDE_SETTINGS[k]
	},

	projSetting: function (k, v) {
		if (v != null) {
			app.project_settings[k] = v;
			// app.saveSettings();
		}
		if (!k) return app.project_settings;
		return app.project_settings[k] || DEFAULT_PROJECT_SETTINGS[k]
	},

	project_settings:{},
	loadSettings: function(callback){
		if (app.isProjectOpen()) {	
			nwFS.readFile(nwPATH.join(app.project_path,"config.json"), 'utf-8', function(err, data){
				if (!err || (data && data.length > 1))
					app.project_settings = JSON.parse(data);
				else
					app.project_settings = {};

				ifndef_obj(app.project_settings, DEFAULT_PROJECT_SETTINGS);
				// project settings
				let eng_settings = {};
				(engine.project_settings || []).forEach(s => {
					for (let prop of s) {
						if (typeof(prop) == "object" && prop.default)
							eng_settings[s[0]] = prop.default;
					}
				});
				app.project_settings = Object.assign({}, app.project_settings, eng_settings);
				app.saveSettings();
				if (callback) callback();
			});
		}
	},
	saveSettings: function(){
		if (app.isProjectOpen()) {
			nwFS.writeFile(nwPATH.join(app.project_path,"config.json"), JSON.stringify(app.project_settings, null, 4));
		}
	},

	hideWelcomeScreen: function() {
		app.getElement("#welcome").classList.add("hidden");
		app.getElement("#workspace").style.pointerEvents = "";
	},

	showWelcomeScreen: function() {
		app.getElement("#welcome").classList.remove("hidden");
	},

	getNewAssetPath: function (_type, cb) {
		const asset_dir = nwPATH.join(app.project_path, 'assets', _type);
		nwFS.ensureDir(asset_dir, err => {
			nwFS.readdir(asset_dir, (err, files) => {
				let num = files.length;
				let fpath = nwPATH.join(asset_dir, _type+num+'.'+app.allowed_extensions[_type][0])
				while (nwFS.pathExistsSync(fpath)) {
					num++;
					fpath = nwPATH.join(asset_dir, _type+num+'.'+app.allowed_extensions[_type][0]);
				}
				cb(app.cleanPath(fpath), nwPATH.basename(fpath));
			});
		});
	},

	addAsset: function(res_type, path) {
		blanke.toast("adding file \'"+nwPATH.basename(path)+"\'");
		nwFS.ensureDir(nwPATH.join(app.project_path, 'assets', res_type), (err) => {
			if (err) console.error(err);
			let asset_path = nwPATH.join(app.project_path, 'assets', res_type, nwPATH.basename(path))
			nwFS.copySync(path, asset_path);
			dispatchEvent("asset_added",{type: res_type, path: asset_path});
		});
	},

	// determine an assets type based on file extension
	// returns: image, audio, other
	allowed_extensions: {
		'image':['png','jpg','jpeg'],
		'audio':['mp3','ogg','wav'],
		'font':['ttf','ttc','cff','woff','otf','otc','pfa','pfb','fnt','bdf','pfr'],
		'script':['js'],
		'map':['map']
	},
	name_to_path: {},
	asset_list: [],
	getAssets: function(f_type, cb) {
		let extensions = [];
		let all_assets = false;
		if (cb)
			extensions = app.allowed_extensions[f_type];
		else {
			cb = f_type;
			all_assets = true;
			extensions = [].concat.apply([], Object.values(app.allowed_extensions));
		}
		if (!extensions) return;
		
		let walker = nwWALK.walk(app.project_path);
		let ret_files = [];
		walker.on('file',function(path, stats, next){
			// only add files that have an extension in allowed_extensions
			if (stats.isFile() && !path.includes('dist') && extensions.includes(nwPATH.extname(stats.name).slice(1))) {
				ret_files.push(app.cleanPath(nwPATH.join(path, stats.name)));
			}
			next();
		});
		walker.on('end',function(){
			if (all_assets)
				app.asset_list = ret_files;
			if (cb) cb(ret_files);
		});
	},
	findAssetType: function(path) {
		let ext = nwPATH.extname(path).substr(1);
		for (let a_type in app.allowed_extensions) {
			if (app.allowed_extensions[a_type].includes(ext))
				return a_type;
		}
		return 'other';
	},
	shortenAsset: function(path){
		path = app.cleanPath(path);
		return app.cleanPath(nwPATH.relative(app.project_path,path)).replace(/assets[/\\]/,'');
	},
	lengthenAsset: function(path){
		path = app.cleanPath(path);
		return nwPATH.resolve(nwPATH.join(app.project_path,'assets',path));
	},
	getAssetPath: function(_type, name, cb) {
		if (!name) {
			if (_type == 'scripts')
				return app.cleanPath(nwPATH.resolve(engine.script_path));
			else if (_type)
				return app.cleanPath(nwPATH.resolve(nwPATH.join(app.project_path,'assets',_type)));
			else 
				return app.cleanPath(nwPATH.resolve(nwPATH.join(app.project_path,'assets')));
		}
		app.getAssets(_type, (files) => {
			let found = false;
			let re_name = /[\\\/](([\w\s.-]+)\.\w+)/;
			files.forEach((f) => {
				let match = re_name.exec(f);
				if (match && (match[1] == name || match[2] == name)) {
					found = true;
					cb(false, app.lengthenAsset(app.cleanPath(nwPATH.join(_type,match[1]))));
				}
			});
			if (!found)
				cb(true);
		});
	},
	cleanPath: function(path) {
		if (path) return path.replaceAll(/\\/g,'/');
	},
	showDropZone: function() {
		if (app.isProjectOpen())
			app.getElement("#drop-zone").classList.add("active");
	},
	hideDropZone: function() {
		app.getElement("#drop-zone").classList.remove("active");
	},
	dropFiles: function(files) {
		for (let f of files) {
			nwFS.stat(f.path, (err, stats) => {
				if (err || !stats.isFile())
					blanke.toast(`Could not add file ${f.path}`);
				else 
					app.addAsset(app.findAssetType(f.path),f.path);
			});
		}
		app.hideDropZone();
	},
	workspace_margin_top: 34,
	flashCrosshair: function(x, y) {
		let el_cross = app.createElement("div","crosshair");
		let el_crossx = app.createElement("div","x");
		let el_crossy = app.createElement("div","y");
		el_cross.appendChild(el_crossx);
		el_cross.appendChild(el_crossy);

		el_crossx.style.left = x+"px";
		el_crossy.style.top = (y+app.workspace_margin_top)+"px";

		app.getElement("body").appendChild(el_cross);
		setTimeout(function(){
			blanke.destroyElement(el_cross);
		}, 1000);
	},

	// shows when nothing is open
	last_quick_access: '',
	_refreshQuickAccess: (hash) => {
		if (app.isProjectOpen()) {
			let set = app.projSetting();
			if (hash) {
				let last_hash, last_title;
				set.quick_access = set.quick_access.filter(h => {
					if (h[0] == hash || h[1] == hash) {
						last_hash = h[0]
						last_title = h[1];
						hash = last_hash;
					} else
						return true;
				});
				for (let key in app.search_titles) {
					val = app.search_titles[key];
					if (val == hash) // switch them around here
						hash = key;
				}
				hash = hash || last_hash;
				let title =  app.search_titles[hash] || last_title;
				if (hash && title && app.isSearchKey(hash)) 
					set.quick_access.unshift([hash,title]);
			}
			if (!set.quick_access) return;
			set.quick_access = set.quick_access.slice(0,app.ideSetting("quick_access_size"));
			app.saveSettings();
			let el_container = app.getElement("#recents-container");
			// check if anything needs to be changed
			//let different = false;
			if (el_container.childElementCount == 0) {
				//different = true;
			} else {
				for (let h = 0; h < el_container.childElementCount; h++) {
					if (!set.quick_access[h])
						;//different = true;
					else {
						let hash = set.quick_access[h][0];
						let child = el_container.children.item(h);
						if (!child || child.hash != hash) {
							//different = true;
						}
						if (!child.text || child.text.trim() == "")
							blanke.destroyElement(child);
					}
				}
			}
			// remake quick access list
			let different = JSON.stringify(set.quick_access) !== app.last_quick_access
			if (different) {
				app.last_quick_access = JSON.stringify(set.quick_access)
				app.clearElement(el_container);

				let el_title = app.getElement("#recent-history > .title-container")
				if (set.quick_access.length == 0)
					el_title.classList.add('hidden');
				else
					el_title.classList.remove('hidden');
				
				for (let h of set.quick_access) {
					if (h[0] && h[1]) {
						let el_link_container = app.createElement('div','history-container');
						let el_link = app.createElement('a','history');
						el_link.innerHTML = h[1];
						el_link_container.onclick = ()=>{
							app.triggerSearchKey(h[0]);
						}
						el_link_container.appendChild(el_link);
						el_link_container.hash = h[0];
						el_link_container.text = h[1];
						el_container.appendChild(el_link_container);
					}
				}
			}
			// show quick access only if workspace is empty
			if (app.getElement("#workspace").childElementCount == 0)
				app.getElement("#recent-history").classList.remove("hidden");
			else
				app.getElement("#recent-history").classList.add("hidden");
		}
		app.refreshQuickAccess(null, true);
	},
/*
	removeQuickAccess: (hash) => {
		app.projSetting("quick_access") = app.projSetting("quick_access").filter(q => q[0] !== hash)
		app.saveSettings();
		app.refreshQuickAccess();
	},
*/
	refreshQuickAccess: (hash, not_now) => {
		if (!not_now) // double negative lol
			app._refreshQuickAccess(hash);
		blanke.cooldownFn('refreshQuickAccess',2000,()=>{
			app._refreshQuickAccess(hash);
		})
	},

	removeQuickAccess: (text) => {
		// remove element 
		let hash;
		let el_container = app.getElement("#recent-history");
		// check if anything needs to be changed
		let different = false;
		if (el_container.childElementCount > 0) {
			for (let h = 0; h < el_container.childElementCount; h++) {
				let child = el_container.children.item(h);
				if (child.text == text) {
					hash = child.hash;
					blanke.destroyElement(child);
				}
			}
		}
		// change settings
		//if (hash) {
			app.projSetting("quick_access",app.projSetting("quick_access").filter(h => (!hash || h[0] != hash) && h[1] != text))
			app.saveSettings();
		//}
		app.refreshQuickAccess();
	},

	pending_quick_access: [],
	addPendingQuickAccess: (file) => {
		app.pending_quick_access.push(file);
	},

	// TAB BAR (history)
	history_ref: {},
	addHistory: function(title) {
		// check if it already exists
		let exists = null;
		for (let id in app.history_ref) {
			let e = app.history_ref[id];
			if (e.title == title) {
				exists = id;
			}
		}

		let el_history_bar = app.getElement("#history");

		if (exists != null) {
			return app.setHistoryMostRecent(exists);

		} else {
			// add a new entry
			let id = guid();

			let entry = app.createElement("div","entry");
			let entry_title_container = app.createElement("div","entry-title-container");
			let entry_title = app.createElement("div","entry-title");
			let tab_tri_left = app.createElement("div", "triangle-left");
			let tab_tri_right = app.createElement("div", "triangle-right");

			entry.dataset.guid = id;
			// entry.dataset.type = content_type;
			entry_title_container.appendChild(entry_title)

			entry.appendChild(entry_title_container);
			entry.appendChild(tab_tri_left);
			entry.appendChild(tab_tri_right);
			el_history_bar.appendChild(entry);

			app.history_ref[id] = {'entry':entry, 'entry_title':entry_title, 'title':title, 'active':true};
			app.setHistoryHighlight(id);
			return id;
		}
	},

	setHistoryMostRecent: function(id, skip_highlight) {
		if (!app.history_ref[id]) return;
		
		let e = app.history_ref[id];
		if (!e) return;
		let el_history_bar = app.getElement("#history");

		// move it to front of history
		el_history_bar.removeChild(e.entry);
		el_history_bar.appendChild(e.entry);
		if (!skip_highlight)
			app.setHistoryHighlight(id);

		app.refreshQuickAccess(app.search_titles[id]);
		return e.entry.dataset.guid;
	},
	
	setHistoryClick: function(id, fn_onclick) {
		if (app.history_ref[id]) {
			app.history_ref[id].entry_title.addEventListener('click',function(){
				fn_onclick();
				if (!app.history_ref[id] || !app.history_ref[id].active) {
					app.setHistoryMostRecent(id);
				}
			});
		}
	},

	setHistoryContextMenu: function(id, fn_onmenu) {
		if (app.history_ref[id]) app.history_ref[id].entry.oncontextmenu = fn_onmenu;
	},

	setHistoryActive: function(id, yes) {
		if (app.history_ref[id]) {
			app.history_ref[id].active = yes ? true : false;
			if (yes) app.history_ref[id].entry.classList.add("open");
			else app.history_ref[id].entry.classList.remove("open");
		}
	},

	last_history_highlight: [],
	setHistoryHighlight: function(id) {
		if (app.history_ref[id]) {
			app.last_history_highlight.unshift(id);
			for (let other_id in app.history_ref) {
				app.history_ref[other_id].entry.classList.remove("highlighted");
			}
			app.history_ref[id].entry.classList.add("highlighted");
		} else if (app.last_history_highlight[0] && !id) {
			app.setHistoryHighlight(app.last_history_highlight[0])
		}
	},

	setHistoryText: function(id, text) {
		if (app.history_ref[id]) {
			app.history_ref[id].entry_title.innerHTML = text;
			app.history_ref[id].title = text;

			for (let h in app.history_ref) {
				if (app.history_ref[h].title == text && h != id)
					app.removeHistory(h);
			}
		}
	},

	removeHistory: function(id) {
		if (!app.history_ref[id]) return;
		blanke.destroyElement(app.history_ref[id].entry);
		delete app.history_ref[id];
		let i = app.last_history_highlight.indexOf(id)
		if (i > -1) app.last_history_highlight.splice(i,1);
		app.setHistoryHighlight();
	},

	clearHistory: function() {
		let history_ids = Object.keys(app.history_ref);
		for (let h = 0; h < history_ids.length; h++) {
			app.removeHistory(history_ids[h]);
		}
		app.getElement("#history").innerHTML = "";
	},

	// rename a file only if the new path doesn't exist
	renameSafely: function(old_path, new_path, fn_done) {
		nwFS.pathExists(new_path, (err, exists) => {
			// file exists
			if (exists && fn_done) 
				fn_done(false, 'file exists');
			else {
				// does not exist, continue with renaming
				nwFS.rename(old_path, new_path, (err) => {
					if (err)
						fn_done(false, err);
					else {
						// rename in quick access if it's there
						let old_name = nwPATH.basename(old_path);
						let new_name = nwPATH.basename(new_path);
						for (let pair of app.projSetting("quick_access")) {
							for (let p in pair) {
								pair[p] = pair[p].replace(old_name, new_name)
							}
						}
						app.saveSettings();
						fn_done(true);
					}
				})
			}
		})
	},

	// makes all urls open in external window
	sanitizeURLs () {
		Array.from(document.getElementsByTagName("a")).forEach(a => {
			if (a.href.length > 0) {
				a.target="_blank"
				if (!a.title && a.href.length > 1)
					a.title = a.href;
			}
		})
	},

	enableDevMode(force_search_keys) {
		if (!DEV_MODE || force_search_keys) {
			DEV_MODE = true;
			app.addSearchKey({key: 'Dev Tools', onSelect: app.window.webContents.openDevTools});
			app.addSearchKey({key: 'View APPDATA folder', onSelect:function(){ elec.shell.openItem(app.getAppDataFolder()); }});
			app.window.webContents.openDevTools();
			blanke.toast("Dev mode enabled");
		} else {
			blanke.toast("Dev mode already enabled!");
		}
	},

	curr_version: '',
	checkForUpdates(silent) {
		let curr_version_list = JSON.parse(nwFS.readFileSync(nwPATH.join('src','version.json')));
		app.curr_version = Object.keys(curr_version_list)[0];
		let is_newer = (ver_str) => {
			curr_ver = app.curr_version.split('-')[0].split('.');
			new_ver = ver_str.split('-')[0].split('.');
			for (let p in new_ver) { 
				if (parseInt(curr_ver[p]) < parseInt(new_ver[p]))
					return true;
			}
			return false;
		}
		// check latest version
		nwREQ.get('https://raw.githubusercontent.com/xharris/blankejs/master/src/version.json', (err, res, body)=>{
			if (!err && res.statusCode == 200) {
				let updates = JSON.parse(body);
				let update_string = '';
				let keys = Object.keys(updates);
				let latest_version = '';
				let manual = false;
				for (let k = keys.length-1; k >= 0; k--) {
					latest_version = keys[k].split('-')[0];
					if (!keys[k].includes('skip') && is_newer(keys[k])) {
						update_string += `<div class='version-container'><div class='number'>${latest_version}</div><div class='notes'>${updates[keys[k]].join('\n')}</div></div>`;
					}
					if (keys[k].includes('wait') && is_newer(keys[k])) {
						manual = true
						k = -1;
					}
				}
				if (update_string != '') {
					blanke.toast('An update is available! ('+latest_version+')');
					app.getElement('#btn-update').classList.remove('hidden');

					// ask if it can be installed now
					app.getElement('#btn-update').addEventListener('click',(e)=>{
						blanke.showModal(`<div class="update-title">${manual ? 'Manual install required. Go to download page' : 'Download, Install, and Restart'}?</div><div class='info'>${update_string}</div>`,{
							"yes":function(){ 
								if (manual)
									elec.shell.openExternal('https://xhh.itch.io/blanke')
								else
									app.update(latest_version);
							},
							"no":function(){}
						});
					});
				} else {
					if (!silent) blanke.toast('Already up to date! ('+app.curr_version+')');
				}
			}
		});
	},

	update2() {
		nwREQ(`https://raw.githubusercontent.com/xharris/blankejs/master/electron.asar`)
			.pipe(nwFS.createWriteStream('update.asar'))
			.on()
	},

	update(ver) {
		// download new version
		let toast = blanke.toast('Downloading update',-1);
		toast.icon = 'dots-horizontal';
		toast.style = 'wait';
		nwREQ(`https://github.com/xharris/blankejs/archive/${ver}.zip`)
			.pipe(nwFS.createWriteStream('update.zip'))
			.on('close',function(){
				blanke.toast('Installing update');
				let update_zip = nwZIP2('update.zip');//.extractEntryTo('blankejs-'+ver,cwd(),false,true)
				let file_paths = update_zip.getEntries();
				let limit = 3;
				let entryName;
				let actual_src = [/blankejs[\/\\]/,/src[\/\\]/,/themes[\/\\]/,'package.json','entry.js'];
				// unpack new files
				for (let f = 0; f < file_paths.length; f++) {
					entryName = file_paths[f].entryName;
					for (let src of actual_src) {
						if (entryName.match(src) && !entryName.endsWith('\/') && !nwPATH.basename(entryName).startsWith('.')){
							update_zip.extractEntryTo(entryName, nwPATH.dirname(nwPATH.join(cwd(), entryName.replace(/^[^\/\\]*[\/\\]/,''))), false, true);
						} 
					}
					if (entryName.match(/dist_files[\/\\]/)) {
						update_zip.extractEntryTo(entryName, nwPATH.dirname(nwPATH.join(cwd(), nwPATH.basename(entryName))), false, true);
					}
				}
				nwFS.removeSync('update.zip');
				toast.text = 'Done updating. Restarting';
				// restart app
				app.restart();
			})
			.on('error',(err)=>{
				app.error('Could not download update',err);

			});
	},

	restart () {
		elec.remote.app.relaunch();
		elec.remote.app.exit();
	},
	error_toast: null,
	error (e) {
		nwFS.appendFile(nwPATH.join(app.getAppDataFolder(),'error.txt'),'[[ '+Date.now()+' ]]\r\n'+Array.prototype.slice.call(arguments).join('\r\n')+'\r\n\r\n',(err)=>{
			if (!app.error_occured) {
				app.error_occured = e;
				blanke.toast(`Error! See <a href="#" role="button" onclick="app.openErrorFile()">error.txt</a> for more info`,-1);
				app.sanitizeURLs();
			}
		});
	},

	openErrorFile () {
		elec.shell.openItem(nwPATH.join(app.getAppDataFolder(),'error.txt'));
	},

	shortcut_log: {},
	newShortcut (options) {
		app.shortcut_log[options.key] = options;
		elec.remote.globalShortcut.register(options.key,options.active)
	}
}

app.window.webContents.on('open-file', (e, path)=>{
	//console.log(e)
})
document.addEventListener('click', function (event) {
	if (event.target.tagName === 'A') {
		event.preventDefault()
		if (event.target.href.startsWith('http')) {
			elec.shell.openExternal(event.target.href)
		}
	}
})
app.window.webContents.once('dom-ready', ()=>{
	process.chdir(nwPATH.join(__dirname,'..'));
	blanke.elec_ref = elec;

	app.window.on('blur', ()=>{ elec.remote.globalShortcut.unregisterAll(); })
	app.window.on('focus', ()=>{
		for (let name in app.shortcut_log) {
			app.newShortcut(app.shortcut_log[name]);
		}
	})
	if (process.argv[1]) {
		// console.log(process.argv);
	}

	app.refreshQuickAccess();

	// remove error file
	nwFS.remove(nwPATH.join(app.getAppDataFolder(),'error.txt'));

	// index.html button events
	app.getElement("#btn-close").addEventListener('click',()=> { app.window.close() });
	app.getElement("#btn-maximize").addEventListener('click',()=> { app.window.isMaximized() ? app.window.unmaximize() : app.window.maximize() });
	app.getElement("#btn-minimize").addEventListener('click',()=> { app.window.minimize() });
	app.getElement("#btn-play").addEventListener('click',()=> { app.play() });
	app.getElement("#btn-export").addEventListener('click',()=> { new Exporter() });
	app.getElement("#btn-winvis").addEventListener('click',()=> { app.toggleWindowVis() });
	app.getElement("#btn-winsplit").addEventListener('click',()=> { app.toggleSplit() });
	app.getElement("#btn-docs").addEventListener('click',()=> { new Docview() });
	app.getElement("#btn-plugins").addEventListener('click',()=> { new Plugins() });
	app.getElement("#btn-settings").addEventListener('click',()=> { new Settings() });

	app.getElement("#btn-winsplit").title = "toggle window splitting "+(split_enabled == true ? '(ON)' : '(OFF)');
	

	let os_names = {"Linux":"linux", "Darwin":"mac", "Windows_NT":"win"};
	app.os = os_names[nwOS.type()];
	document.body.classList.add(app.os);

	/*
	window.onerror = (...args) => {
		console.log(args);
	}
	*/

	window.addEventListener("error", function(e){
		if (e.error)
			app.error(e.error.stack);
		else 
			app.error(JSON.stringify(e));
	});

	// changing searchbox placeholder between "Some title" and "Search..."
	let el_search_input = app.getElement("#search-input");
	el_search_input.addEventListener("mouseenter",function(e){
		el_search_input.placeholder = "Search...";
	});
	el_search_input.addEventListener("focus",function(e){
		el_search_input.placeholder = "Search...";
	});

	el_search_input.addEventListener("blur",function(e){
		if (document.activeElement !== e.target) el_search_input.placeholder = app.win_title;
	});
	el_search_input.addEventListener("mouseleave",function(e){
		if (document.activeElement !== e.target) el_search_input.placeholder = app.win_title;
	});

	// Welcome screen

	// new project
	app.getElement("#btn-new").addEventListener('click',function(e){ 
		app.newProjectDialog();
	});

	// open project
	app.getElement("#btn-open").addEventListener('click',function(e){ 
		app.openProjectDialog();
	});

	// prepare search box
	app.getElement("#search-input").addEventListener('input', function(e){
		let input_str = e.target.value;
		let el_result_container = app.getElement("#search-results");
		if (input_str.length > 0) {
			let categories = {};
			let results = app.search_hashvals.filter(val => val.toLowerCase().includes(input_str.toLowerCase()));
			app.clearElement(el_result_container);

			// add results to div
			for (var r = 0; r < results.length; r++) {
				let hash = results[r];
				let result = app.unhashSearchVal(hash);
				let category = app.getSearchCategory(hash);

				// add category div
				if (category && !categories[category]) {
					let el_category = app.createElement("div","category-container");
					el_category.is_category = true;

					el_category.el_title = app.createElement("p","title");
					el_category.el_title.innerHTML = category;
					
					el_category.el_children = app.createElement("div","children");

					el_category.append(el_category.el_title);
					el_category.append(el_category.el_children);
					el_result_container.append(el_category);
					categories[category] = el_category;
				}

				let el_result = app.createElement("div", "result");
				el_result.innerHTML = result.key;
				el_result.dataset.hashval = hash;
				el_result.dataset.func = app.search_funcs[hash];

				if (category)
					categories[category].el_children.append(el_result);
				else
					el_result_container.append(el_result);
			}
		} else {
			app.clearElement(el_result_container);
		}
	})
	function selectSearchResult(hash_val) {
		selected_index = -1;
		app.triggerSearchKey(hash_val);
	}

	app.getElement("#search-results").addEventListener('click', function(e){
		if (e.target && e.target.classList.contains('result')) {
			selectSearchResult(e.target.dataset.hashval);
		}
	});

	// moving through/selecting options
	var selected_index = -1;
	app.getElement("#search-input").addEventListener('keyup', function(e){
		var keyCode = e.keyCode || e.which;

		// ENTER
		if (keyCode == 13) {
			if (selected_index >= 0) {
				var child = app.getSearchResults()[selected_index];
				if (child) {
					var hash_val = child.dataset.hashval;
					selectSearchResult(hash_val);
				}
			}
		}
	});

	app.getElement("#search-input").addEventListener('keydown', function(e){
		var keyCode = e.keyCode || e.which;

		// TAB
		if (keyCode == 9) {
			e.preventDefault();

			let el_results = app.getSearchResults();
			var num_results = el_results.length;

			if (num_results > 0) {
				if (e.shiftKey)
					selected_index -= 1;
				else
					selected_index += 1;

				if (selected_index < 0) 			selected_index = num_results - 1;
				if (selected_index >= num_results) 	selected_index = 0;

				// highlight selected result
				el_results.forEach((e, i) => {
					if (i === selected_index) {
						e.classList.add('focused');
						e.scrollIntoView({behavior:"smooth",block:"nearest"})
					} else
						e.classList.remove('focused');
				});
			} else {
				selected_index = -1;
			}
		}
	});
	
	// shortcut: focus search box
	app.newShortcut({
		key: "CommandOrControl+R",
		active: function() {
			app.getElement("#search-input").focus();
		}
	});
	// shortcut: enable dev mode
	app.newShortcut({
		key: "CommandOrControl+Shift+D",
		active: function() {
			app.enableDevMode();
		}
	});
	// shortcut: relaunch app
	app.newShortcut({
		key: "CommandOrControl+Shift+R",
		active: function() {
			app.restart();
		}
	})
	// shortcut: shift window focus
	app.newShortcut({
		key: "CommandOrControl+T",
		active: function() {
			var windows = app.getElements(".drag-container");
			if (windows.length > 1) {
				var index = 0;
				for (index = 0; index < windows.length; index++) {
					if (windows[index].classList.contains('focused')) {
						break;
					}
				}
				index += 1;
				if (index >= windows.length) index = 0;
				windows[index].click();
			}
		}
	});
	// shortcut: PREVENT refreshing
	app.newShortcut({
		key: "CommandOrControl+R",
		active: function() {}
	})

	app.window.on('closed',function(){
		this.hide();
		app.closeProject();
		// close extra windows
		for (let win of app.extra_windows) {
			win.close(true);
		}
		this.close(true);
	});

	// prevents text from becoming blurry
	app.window.on('resize',(e)=>{
		blanke.cooldownFn('window_resize',500,()=>{
			let size = e.sender.getSize();
			app.window.setSize(parseInt(size[0]), parseInt(size[1]))
		})
	});

	// file drop zone
	window.addEventListener('dragover', function(e) {
		e.preventDefault();
		app.showDropZone();
		return false;
	});
	window.addEventListener('drop', function(e) {
		e.preventDefault();

		if (app.isProjectOpen()) {
			app.dropFiles(e.dataTransfer.files);
			app.getElement("#drop-zone").classList.remove("active");
		}

		return false;
	});
	window.addEventListener('dragleave', function(e) {
		e.preventDefault();
		app.hideDropZone();
		return false;
	});

	app.addSearchKey({key: 'Open project', onSelect: function() {
		app.openProjectDialog();
	}});
	app.addSearchKey({key: 'New project', onSelect: function() {
		app.newProjectDialog();
	}});

	if (DEV_MODE) {
		app.enableDevMode(true);
	}
	app.addSearchKey({key: 'Start Server', category:'tools', onSelect: app.runServer});
	app.addSearchKey({key: 'Stop Server', category:'tools', onSelect: app.stopServer});
	app.addSearchKey({key: 'Check for updates', onSelect: app.checkForUpdates});

	document.addEventListener("openProject",function(){
		app.addSearchKey({key: 'View project in explorer', onSelect: function() {
			elec.shell.openItem(app.project_path);
		}});
		app.addSearchKey({key: 'Close project', onSelect: function() {
			app.closeProject();
		}});
		app.addSearchKey({key: 'Clear history', onSelect: () => {
			app.clearHistory();
		}})
		app.refreshQuickAccess();
	});

	document.addEventListener("pluginChanged",function(){
		app.minifyEngine();
	});

	app.loadAppData(function(){
		// load current theme
		app.setTheme(app.ideSetting("theme"));

		// add recent projects (max 10)
		var el_recent = app.getElement("#welcome .recent-files");
		if (app.ideSetting("recent_files").length > 10) 
			app.ideSetting("recent_files",app.ideSetting("recent_files").slice(0,10))
			
		// setup welcome screen
		let el_br = app.createElement("br");

		elec.remote.app.clearRecentDocuments();
		app.ideSetting("recent_files").forEach((file) => {
			if (nwFS.pathExistsSync(file) && nwFS.statSync(file).isDirectory()) {
				let el_file = app.createElement("button", "file");
				el_file.innerHTML = nwPATH.basename(file);
				el_file.title = file;
				el_file.addEventListener('click',function(){
					app.openProject(file);
				});

				el_recent.appendChild(el_file);
				el_recent.appendChild(el_br)

				elec.remote.app.addRecentDocument(file);
			}
		})
		
		app.showWelcomeScreen();
		app.checkForUpdates(true);
		dispatchEvent("ideReady");

		// app.openProject('projects/test zone');
	});
});
