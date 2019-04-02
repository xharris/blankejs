/*

C - completed
T - completed but needs more testing

TODO:
C	separate tabs from history bar
C	implement fibonnaci-sized windows
C	sprite sheet preview: should display image dimensions
-	find and replace		

BUGS:
- 	mapeditor: should only place tile on map if the mouse started inside the canvas on mouse down
T 	sceneeditor: pointerup event after pointerdown event happens outside of window --> freeze
T	sceneeditor: create new scene, remove premade layers, rename layer -> other layers come back
T 	sceneeditor: image search keys still remain after closing scene editor
T	sceneeditor: re-opening opens 3 instances
*/
var nwGUI = require('nw.gui');
var nwFS = require('fs-extra');
var nwWALK = require('walk');
var nwPATH = require('path');
var nwOS = require('os');
var nwWIN = nwGUI.Window.get();
const { spawn, execFile, exec } = require('child_process')
const { cwd, env, platform } = require('process')
var nwNOOB = require('./js/server.js');
var nwZIP = require('archiver');
var nwZIP2 = require('adm-zip');
var nwWATCH = require('node-watch');
var nwREQ = require('request');

var app = {
	project_path: "",
	watch: null,
	game_window: null,
	maximized: false,
	os: null, // win, mac, linux,
	error_occured: null,

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
		var menu = new nwGUI.Menu();
		for (var i = 0; i < items.length; i++) {
			var menuitem = menu.append(new nwGUI.MenuItem(items[i]));
		}
		menu.popup(x, y);
	},

	close: function() {
		nwWIN.close();
	},

	maximize: function() {
		if (app.maximized) nwWIN.unmaximize();
		else nwWIN.maximize();
		app.maximized = !app.maximized;
	},

	minimize: function() {
		nwWIN.minimize();
	},

	getRelativePath: function(path) {
		return nwPATH.relative(app.project_path,path);
	},

	isProjectOpen: function() {
		return (app.project_path && app.project_path != "");
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
		blanke.chooseFile('nwdirectory', function(file_path){
			blanke.showModal(
				"<label style='line-height:35px'>new project name:</label></br>"+
				"<label>"+file_path+"\\</label>"+
				"<input class='ui-input' id='new-proj-name' style='width:100px;' value='my_project'/>",
			{
				"yes": function() { app.newProject(nwPATH.join(file_path, app.getElement('#new-proj-name').value)); },
				"no": function() {}
			});
		}, true);
	},

	win_title: '',
	setWinTitle: function(title) {
		app.win_title = title;
		app.getElement("#search-input").placeholder = title;
	},

	closeProject: function() {
		if (app.isProjectOpen()) {
			// app.saveSettings();
			app.getElement("#search-container").classList.add("no-project");
			if (app.isServerRunning()) 
				app.stopServer();

			dispatchEvent("closeProject", {path: app.project_path});
			app.project_path = '';
			Editor.closeAll();
			app.clearHistory();
			app.showWelcomeScreen();
			app.setWinTitle("BlankE");
		}
	},

	openProject: function(path) {
		// validate: only open if there's a main.lua
		nwFS.readdir(path, 'utf8', function(err, files){
			if (!err && files.includes('main.lua')) {
				if (app.isProjectOpen())
					app.closeProject();

				app.project_path = path;
				app.loadSettings();

				// watch for file changes
				app.watch = nwWATCH(app.project_path, {recursive: true}, function(evt_type, file) {
					if (file) { dispatchEvent("fileChange", {type:evt_type, file:file}); }
				});

				// add to recent files
				app.settings.recent_files = app.settings.recent_files.filter(e => e != path);
				app.settings.recent_files.unshift(path);
				app.saveAppData();

				app.getElement("#search-container").classList.remove("no-project");
				app.setWinTitle(nwPATH.basename(app.project_path));
				dispatchEvent("openProject", {path: path});
			}
		});
 
	},

	openProjectDialog: function() {
		blanke.chooseFile('nwdirectory', function(file_path){
			app.openProject(file_path);
		}, true);
	},

	play: function(options) { 
		if (app.isProjectOpen()) {
			let love_path = {
				'win': nwPATH.join(app.settings.engine_path,'love.exe'),
				'mac': nwPATH.resolve(nwPATH.join(app.settings.engine_path,'love.app','Contents','MacOS','love'))
			};

			let child = spawn(love_path[app.os], [nwPATH.resolve(app.project_path),'--ide'].concat(options || []), {
				cwd: nwPATH.join(app.settings.engine_path, 'lua')
			});
			let console_window = new Console(child);
			child.on('close', function(){
				console_window.processClosed()
			})
			//child.unref();
			//Editor.closeAll('Console');
		}
	},

	toggleWindowVis: function() {
		DragBox.showHideAll();
	},

	toggleSplit: function() {
		FibWindow.toggleSplit();
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
	hashSearchVal: function(key, tags) {
		return key + '=' + (tags || []).join('+');
	},
	unhashSearchVal: function(hash_val) {
		return {
			key: hash_val.split('=')[0],
			tags: hash_val.split('=')[1].split('+')
		}
	},
	// options: text, description, onSelect, tags
	addSearchKey: function(options) {
		var hash_val = app.hashSearchVal(options.key, options.tags);
		app.search_funcs[hash_val] = options.onSelect;
		app.search_args[hash_val] = options.args;

		if (!app.search_hashvals.includes(hash_val))
			app.search_hashvals.push(hash_val);
		if (options.group) {
			if (!app.search_group[options.group]) app.search_group[options.group] = [];
			app.search_group[options.group].push(hash_val);
		}
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
	},

	removeSearchHash: function(hash) {
		app.search_hashvals = app.search_hashvals.filter(e => e != hash);
		app.search_funcs[hash] = null;
		app.search_args[hash] = null;
	},

	settings: {},
	getAppDataFolder: function(){
		return nw.App.dataPath || (app.os == 'mac' ? nwPATH.join('~','Library','Application Support','BlankE','Default') : '/var/local');
	},
	loadAppData: function(callback) {
		var app_data_folder = app.getAppDataFolder();
		var app_data_path = nwPATH.join(app_data_folder, 'blanke.json');
		nwFS.readFile(app_data_path, 'utf-8', function(err, data){
			if (!err) 
				app.settings = JSON.parse(data);
			else
				app.settings = {};
			ifndef_obj(app.settings, {
				recent_files:[],
				plugin_path:'plugins',
				engine_path:'love2d',
				autocomplete_path:'./autocomplete.js'
			});
			if (callback) callback();
		});
	},

	saveAppData: function() {
		var app_data_folder = app.getAppDataFolder();
		var app_data_path = nwPATH.join(app_data_folder, 'blanke.json');
		console.log(app_data_path)
		
		nwFS.stat(app_data_folder, function(err, stat) {
			if (!stat.isDirectory()) nwFS.mkdirSync(app_data_folder);
			nwFS.writeFile(app_data_path, JSON.stringify(app.settings));
		});
	},

	project_settings:{},
	loadSettings: function(callback){
		if (app.isProjectOpen()) {	
			nwFS.readFile(nwPATH.join(app.project_path,"config.json"), 'utf-8', function(err, data){
				if (!err) {
					if (!err) {
						app.project_settings = JSON.parse(data);
					}
					ifndef_obj(app.project_settings, {
						ico:nwPATH.join('src','logo.ico'),
						icns:nwPATH.join('src','logo.icns'),
					});
					app.saveSettings();
					if (callback) callback();
				}
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
		app.getElement("#workspace").style.pointerEvents = "auto";
	},

	showWelcomeScreen: function() {
		app.getElement("#welcome").classList.remove("hidden");
		app.getElement("#workspace").style.pointerEvents = "none";
	},

	addAsset: function(res_type, path) {
		blanke.toast("adding file \'"+nwPATH.basename(path)+"\'");
		nwFS.ensureDir(nwPATH.join(app.project_path, 'assets', res_type), (err) => {
			if (err) console.error(err);
			nwFS.copySync(path, nwPATH.join(app.project_path, 'assets', res_type, nwPATH.basename(path)));
			dispatchEvent("asset_added",{type: res_type, path: app.project_path});
		});
	},

	// determine an assets type based on file extension
	// returns: image, audio, other
	allowed_extensions: {
		'image':['png','jpg','jpeg'],
		'audio':['mp3','ogg','wav'],
		'scene':['scene'],
		'font':['ttf','ttc','cff','woff','otf','otc','pfa','pfb','fnt','bdf','pfr'],
		'script':['lua']
	},
	getAssets: function(f_type, cb) {
		let extensions = app.allowed_extensions[f_type];
		if (!extensions) return;
		
		let walker = nwWALK.walk(app.project_path);
		let ret_files = [];
		walker.on('file',function(path, stats, next){
			// only add files that have an extension in allowed_extensions
			if (stats.isFile() && extensions.includes(nwPATH.extname(stats.name).slice(1))) {
				ret_files.push(nwPATH.join(path, stats.name));
			}
			next();
		});
		walker.on('end',function(){
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
		return nwPATH.relative(app.project_path,path).replace(/assets[/\\]/,'');
	},
	lengthenAsset: function(path){
		return nwPATH.resolve(nwPATH.join(app.project_path,'assets',path));
	},
	cleanPath: function(path) {
		return nwPATH.normalize(path).replaceAll('\\\\','/');
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

			app.history_ref[id] = {'entry':entry, 'entry_title':entry_title, 'title':title};
			return id;
		}
	},

	setHistoryMostRecent: function(id) {
		let e = app.history_ref[id];
		if (!e) return;
		let el_history_bar = app.getElement("#history");

		// move it to front of history
		el_history_bar.removeChild(e.entry);
		el_history_bar.appendChild(e.entry);

		return e.entry.dataset.guid;
	},

	setHistoryClick: function(id, fn_onclick) {
		if (app.history_ref[id]) {
			app.history_ref[id].entry_title.addEventListener('click',function(){
				fn_onclick();
				app.setHistoryMostRecent(id);
			});
		}
	},

	setHistoryContextMenu: function(id, fn_onmenu) {
		if (app.history_ref[id]) app.history_ref[id].entry.oncontextmenu = fn_onmenu;
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
		blanke.destroyElement(app.history_ref[id].entry);
		blanke.destroyElement(app.history_ref[id].entry_title);
		delete app.history_ref[id];
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
				fn_done(false);
			else {
				// does not exist, continue with renaming
				nwFS.rename(old_path, new_path, (err) => {
					if (err)
						fn_done(false);
					else
						fn_done(true);
				})
			}
		})
	},

	enableDevMode(force_search_keys) {
		if (!DEV_MODE || force_search_keys) {
			DEV_MODE = true;
			app.addSearchKey({key: 'Dev Tools', onSelect: nwWIN.showDevTools});
			app.addSearchKey({key: 'View APPDATA folder', onSelect:function(){ nwGUI.Shell.openItem(app.getAppDataFolder()); }});
			nwGUI.Window.get().showDevTools();
			blanke.toast("Dev mode enabled");
		} else {
			blanke.toast("Dev mode already enabled!");
		}
	},

	curr_version: '',
	checkForUpdates(silent) {
		let curr_version_list = JSON.parse(nwFS.readFileSync(nwPATH.join('src','version.json')));
		app.curr_version = Object.keys(curr_version_list)[0];
		// check latest version
		nwREQ.get('https://raw.githubusercontent.com/xharris/blankejs/master/src/version.json', (err, res, body)=>{
			if (!err && res.statusCode == 200) {
				let updates = JSON.parse(body);
				let update_string = '';
				let keys = Object.keys(updates);
				for (let k = 0; k < keys.length; k++) {
					if (!curr_version_list[keys[k]]) {
						update_string += `<div class='version-container'><div class='number'>${keys[k]}</div><div class='notes'>${updates[keys[k]].join('\n')}</div></div>`;
					}
				}
				if (update_string != '') {
					let latest_version = keys[0];
					blanke.toast('An update is available! ('+latest_version+')');
					app.getElement('#btn-update').classList.remove('hidden');

					// ask if it can be installed now
					app.getElement('#btn-update').addEventListener('click',(e)=>{
						blanke.showModal(`<div class="update-title">Download, Install, and Restart?</div><div class='info'>${update_string}</div>`,{
							"yes":function(){ app.update(latest_version); },
							"no":function(){}
						});
					});
				} else {
					if (!silent) blanke.toast('Already up to date! ('+app.curr_version+')');
				}
			}
		});
	},

	update(ver) {
		// download new version
		blanke.toast('Downloading update');
		nwREQ(`https://github.com/xharris/blankejs/archive/${ver}.zip`)
			.pipe(nwFS.createWriteStream('update.zip'))
			.on('close',function(){
				blanke.toast('Installing update');
				let update_zip = nwZIP2('update.zip');//.extractEntryTo('blankejs-'+ver,cwd(),false,true)
				let file_paths = update_zip.getEntries();
				let limit = 3;
				let entryName;
				let actual_src = [/love2d[\/\\]/,/src[\/\\]/,'package.json'];
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
				blanke.toast('Done updating. Restarting...');
				// restart app
				chrome.runtime.reload();
			})
			.on('error',(err)=>{
				app.error('Could not download update',err);

			});
	},

	error () {
		nwFS.appendFile('error.txt','[[ '+Date.now()+' ]]\r\n'+Array.prototype.slice.call(arguments).join('\r\n')+'\r\n\r\n',(err)=>{
			blanke.toast(`Error! See <a href="#" onclick="nwGUI.Shell.showItemInFolder(nwPATH.join(cwd(),'error.txt'));">error.txt</a> for more info`);
		});
	}
}

nwWIN.on('loaded', function() {
	let os_names = {"Linux":"linux", "Darwin":"mac", "Windows_NT":"win"};
	app.os = os_names[nwOS.type()];
	document.body.classList.add(app.os);

	window.addEventListener("error", function(e){
		app.error_occured = e;
		app.error(e.error.stack);
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
	var el_new_proj = app.getElement("#welcome .new");
	el_new_proj.onclick = function(){ 
		app.newProjectDialog();
	}

	// open project
	var el_open_proj = app.getElement("#welcome .open");
	el_open_proj.onclick = function(){ 
		app.openProjectDialog();
	}

	// prepare search box
	app.getElement("#search-input").addEventListener('input', function(e){
		var input_str = e.target.value;
		var el_result_container = app.getElement("#search-results");
		if (input_str.length > 0) {
			var results = app.search_hashvals.filter(val => val.toLowerCase().includes(input_str.toLowerCase()));
			app.clearElement(el_result_container);

			// add results to div
			for (var r = 0; r < results.length; r++) {
				var result = app.unhashSearchVal(results[r]);
				var el_result = app.createElement("div", "result");
				el_result.innerHTML = result.key;
				el_result.dataset.hashval = results[r];
				el_result.dataset.func = app.search_funcs[results[r]];
				el_result_container.append(el_result);
			}
		} else {
			var el_result_container = app.getElement("#search-results");
			app.clearElement(el_result_container);
		}
	})
	function selectSearchResult(hash_val) {
		app.search_funcs[hash_val].apply(this, app.search_args[hash_val]);
		var el_search = app.getElement("#search-input")
		el_search.value = "";
		el_search.blur();
		app.clearElement(app.getElement("#search-results"));

		// move found value up in list
		app.search_hashvals = app.search_hashvals.filter(e => e != hash_val);
		app.search_hashvals.unshift(hash_val);
		selected_index = -1;
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
				var child = app.getElement("#search-results").children[selected_index];
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

			var el_result_container = app.getElement("#search-results");
			var num_results = el_result_container.children.length;

			if (num_results > 0) {
				if (e.shiftKey)
					selected_index -= 1;
				else
					selected_index += 1;

				if (selected_index < 0) 			selected_index = num_results - 1;
				if (selected_index >= num_results) 	selected_index = 0;

				// highlight selected result
				Array.from(el_result_container.children).forEach(function(e){
					e.classList.remove('focused');
				});
				let el_focused = el_result_container.children[selected_index];
				el_focused.classList.add('focused');
				el_focused.scrollIntoView({behavior:"smooth",block:"nearest"})
			} else {
				selected_index = -1;
			}
		}
	});

	// shortcut: focus search box
	nwGUI.App.registerGlobalHotKey(new nwGUI.Shortcut({
		key: "Ctrl+R",
		active: function() {
			app.getElement("#search-input").focus();
		}
	}));
	// shortcut: enable dev mode
	nwGUI.App.registerGlobalHotKey(new nwGUI.Shortcut({
		key: "Ctrl+Shift+D",
		active: function() {
			app.enableDevMode();
		}
	}));
	nwGUI.App.registerGlobalHotKey(new nwGUI.Shortcut({
		key: "Command+Shift+D",
		active: function() {
			app.enableDevMode();
		}
	}));
	// shortcut: shift window focus
	nwGUI.App.registerGlobalHotKey(new nwGUI.Shortcut({
		key: "Ctrl+T",
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
	}));

	nwWIN.on('close',function(){
		this.hide();
		app.closeProject();
		this.close(true);
	});

	// file drop zone
	window.addEventListener('dragover', function(e) {
		e.preventDefault();
		if (app.isProjectOpen())
			app.getElement("#drop-zone").classList.add("active");
		return false;
	});
	window.addEventListener('drop', function(e) {
		e.preventDefault();

		if (app.isProjectOpen()) {
			let files = e.dataTransfer.files;
			for (let f of files) {
				nwFS.stat(f.path, (err, stats) => {
					if (err || !stats.isFile())
						blanke.toast(`Could not add file ${f.path}`);
					else 
						app.addAsset(app.findAssetType(f.path),f.path);
				});
			}
			app.getElement("#drop-zone").classList.remove("active");
		}

		return false;
	});
	window.addEventListener('dragleave', function(e) {
		e.preventDefault();
		if (app.isProjectOpen())
			app.getElement("#drop-zone").classList.remove("active");
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
	app.addSearchKey({key: 'Start Server', onSelect: app.runServer});
	app.addSearchKey({key: 'Stop Server', onSelect: app.stopServer});
	app.addSearchKey({key: 'Check for updates', onSelect: app.checkForUpdates});

	document.addEventListener("openProject",function(){
		app.hideWelcomeScreen();

		app.addSearchKey({key: 'View project in explorer', onSelect: function() {
			nwGUI.Shell.openItem(app.project_path);
		}});
		app.addSearchKey({key: 'Close project', onSelect: function() {
			app.closeProject();
		}});
	});

	app.loadAppData(function(){
		// add recent projects (max 10)
		var el_recent = app.getElement("#welcome .recent-files");
		if (app.settings.recent_files.length > 10) 
			app.settings.recent_files = app.settings.recent_files.slice(0,10);
			
		// setup welcome screen
		let el_br = app.createElement("br");
		app.settings.recent_files.forEach((file) => {
			if (nwFS.pathExistsSync(file) && nwFS.statSync(file).isDirectory()) {
				let el_file = app.createElement("button", "file");
				el_file.innerHTML = nwPATH.basename(file);
				el_file.title = file;
				el_file.addEventListener('click',function(){
					app.hideWelcomeScreen();
					app.openProject(file);
				});

				el_recent.appendChild(el_file);
				el_recent.appendChild(el_br)
			}
		})
		
		app.showWelcomeScreen();
		app.checkForUpdates(true);
		dispatchEvent("ideReady");

		// app.openProject('projects/boredom');
		// app.hideWelcomeScreen();
	});
});