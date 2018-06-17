/*
BUGS:
-	deleting a script prevents new ones from being opened for editing
- 	mapeditor: should only place tile on map if the mouse started inside the canvas on mouse down
*/

var nwGUI = require('nw.gui');
var nwFS = require('fs-extra');
var nwWALK = require('walk');
var nwPATH = require('path');
var nwOS = require('os');
var nwWIN = nwGUI.Window.get();
const { spawn, execFile } = require('child_process')
const { cwd, env, platform } = require('process')
var nwNOOB = require('./js/server.js');

var app = {
	project_path: "",
	watch: null,
	game_window: null,
	maximized: false,
	os: null,

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
		return (app.project_path != "");
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

	openProject: function(path) {
		// validate: only open if there's a main.lua
		nwFS.readdir(path, 'utf8', function(err, files){
			if (!err && files.includes('main.lua')) {		
				app.project_path = path;

				// watch for file changes
				app.watch = nwFS.watch(app.project_path, function(evt_type, file) {
					if (file) { dispatchEvent("fileChange", {type:evt_type, file:file}); }
				});

				// add to recent files
				app.settings.recent_files = app.settings.recent_files.filter(e => e != path);
				app.settings.recent_files.unshift(path);
				app.saveAppData();

				dispatchEvent("openProject", {path: path});
			}
		});
 
	},

	openProjectDialog: function() {
		blanke.chooseFile('nwdirectory', function(file_path){
			app.openProject(file_path);
		}, true);
	},

	play: function() { 
		let love_path = {
			'win': nwPATH.join('love2d','love.exe'),
			'mac': nwPATH.resolve(nwPATH.join('love2d','love.app','Contents','MacOS','love'))
		};
		var child = spawn(love_path[app.os], [nwPATH.resolve(app.project_path)]);
		//child.unref();
		Editor.closeAll('Console');
		var console_window = new Console(app, child);
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
		nwNOOB.start(function(address){
			blanke.toast('server started on '+address);
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
	settings: {
		'recent_files':[]
	},
	getAppDataFolder: function(){
		return env.APPDATA || (app.os == 'mac' ? nwPATH.join(env.HOME, 'Library/Preferences') : '/var/local');
	},
	loadAppData: function(callback) {
		var app_data_folder = app.getAppDataFolder();
		var app_data_path = nwPATH.join(app_data_folder, 'blanke.json');
		
		nwFS.readFile(app_data_path, 'utf-8', function(err, data){
			if (!err) {
				app.settings = JSON.parse(data);
			}
			if (callback) callback();
		});
	},

	saveAppData: function() {
		var app_data_folder = app.getAppDataFolder();
		var app_data_path = nwPATH.join(app_data_folder, 'blanke.json');
		nwFS.stat(app_data_folder, function(err, stat) {
			if (!stat.isDirectory()) nwFS.mkdirSync(app_data_folder);
			nwFS.writeFile(app_data_path, JSON.stringify(app.settings));
		});
	},

	project_settings:{},
	loadSettings: function(callback){
		if (app.isProjectOpen()) {	
			nwFS.readFile(nwPATH.join(app.project_path,"ide_data"), 'utf-8', function(err, data){
				if (!err) {
					app.project_settings = JSON.parse(data);
					if (callback) callback();
				}
			});
		}
	},
	saveSettings: function(){
		if (app.isProjectOpen()) {
			nwFS.writeFile(nwPATH.join(app.project_path,"ide_data"), JSON.stringify(app.project_settings));
		}
	},

	hideWelcomeScreen: function() {
		app.getElement("#welcome").classList.add("hidden");
		app.getElement("#workspace-window").classList.add("active");
	},

	addAsset: function(res_type, path) {
		nwFS.copySync(path, nwPATH.join(app.project_path, 'assets', res_type, nwPATH.basename(path)));
	},

	// determine an assets type based on file extension
	// returns: image, audio, other
	allowed_extensions: {
		'image':['png','jpg','jpeg'],
		'audio':['mp3','ogg','wav'],
		'scene':['scene'],
		'script':['lua']
	},
	findAssetType: function(path) {
		let ext = nwPATH.extname(path).substr(1);
		for (let a_type in app.allowed_extensions) {
			if (app.allowed_extensions[a_type].includes(ext))
				return a_type;
		}
		return 'other';
	}
}

nwWIN.on('loaded', function() {
	nwWIN.showDevTools();

	let os_names = {"Linux":"linux", "Darwin":"mac", "Windows_NT":"win"};
	app.os = os_names[nwOS.type()];
	app.loadAppData(function(){
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

		// add recent projects
		var el_recent = app.getElement("#welcome .recent-files");
		app.settings.recent_files.forEach(function(file){
			// dont show recent project if it doesn't exist
			var stat = nwFS.statSync(file);
			if (stat.isDirectory()) {
				var el_file = app.createElement("button", "file");
				el_file.innerHTML = nwPATH.basename(file, nwPATH.extname(file));
				el_file.title = file;
				el_file.onclick = function(){
					app.hideWelcomeScreen();
					app.openProject(file);
				};

				var el_br = app.createElement("br");

				el_recent.appendChild(el_file);
				el_recent.appendChild(el_br);
			} 
		});
	});

	// setup welcome screen
	var el_recent = app.getElement("#welcome > .recent-files");
	if (el_recent) {
		for (var p = 0; p < app.settings.recent_files.length; p++) {
			var el_file = app.createElement("a", "file");
			var file = app.settings.recent_files[p];
			
			el_file.innerHTML = nwPATH.basename(file, nwPATH.extname(file));
			el_file.title = file;
			el_file.href = "#";
			el_recent.appendChild(el_file);
		}
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
	app.getElement("#search-input").addEventListener('keydown', function(e){
		var keyCode = e.keyCode || e.which;

		// ENTER
		if (keyCode == 13) {
			if (selected_index != -1) {
				var hash_val = app.getElement("#search-results").children[selected_index].dataset.hashval;
				selectSearchResult(hash_val);
			}
		}

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
				el_result_container.children[selected_index].classList.add('focused');
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
	// shortcut: run game
	nwGUI.App.registerGlobalHotKey(new nwGUI.Shortcut({
		key: "Ctrl+B",
		active: function() {
			app.play();
		}
	}));
	nwGUI.App.registerGlobalHotKey(new nwGUI.Shortcut({
		key: "Command+B",
		active: function() {
			app.play();
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

	dispatchEvent("ideReady");
	app.addSearchKey({key: 'Open project', onSelect: function() {
		app.openProjectDialog();
	}});
	app.addSearchKey({key: 'New project', onSelect: function() {
		app.newProjectDialog();
	}});
	app.addSearchKey({key: 'Dev Tools', onSelect: nwWIN.showDevTools});
	app.addSearchKey({key: 'Run Server', onSelect: app.runServer});

	document.addEventListener("openProject",function(){
		app.hideWelcomeScreen();
		app.loadSettings();
	});

	// app.openProject('projects/boredom');
	// app.hideWelcomeScreen();
});