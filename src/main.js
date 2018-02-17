var nwGUI = require('nw.gui');
var nwFS = require('fs');
var nwPATH = require('path');
var nwWIN = nwGUI.Window.get();
const { execFile } = require('child_process')
const { cwd } = require('process')

var app = {
	project_path: "",
	watch: null,
	game_window: null,
	maximized: false,

	getElement: function(sel) {
		return document.querySelector(sel);
	},

	getElements: function(sel) {
		return document.querySelectorAll(sel);
	},

	createElement: function(el_type, el_class) {
		var ret_el = document.createElement(el_type);
		if (el_class) ret_el.classList.add(el_class);
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

	isProjectOpen: function() {
		return (app.project_path != "");
	},

	openProject: function(path) {
		app.project_path = path

		// watch for file changes
		app.watch = nwFS.watch(app.project_path, function(evt_type, file) {
			if (file) { dispatchEvent("fileChange", {type:evt_type, file:file}); }
		});

		dispatchEvent("openProject", {path: path}); 
	},

	play: function() {
		var child = execFile(nwPATH.join('love2d','love.exe'), [app.project_path], {detached: true, stdio: ['ignore', 1, 2]});
		child.unref();
		child.stdout.on('data', function(data){console.log(data.toString());});
		child.stderr.on('data', function(data){console.log(data.toString());});
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

		app.search_hashvals.push(hash_val);
		if (options.group) {
			if (!app.search_group[options.group]) app.search_group[options.group] = [];
			app.search_group[options.group].push(hash_val);
		}
	},

	removeSearchGroup: function(group) {
		var group_len = app.search_group[group].length;
		for (var v = 0; v < group_len; v++) {
			app.removeSearchHash(app.search_group[group][v]);
		}
		app.search_group[group] = null;
	},

	removeSearchKey: function(key, tags) {
		var hash_val = app.hashSearchVal(key, tags);
		app.removeSearchHash(hash_val);
	},

	removeSearchHash: function(hash) {
		app.search_hashvals = app.search_hashvals.filter(e => e != hash);
		app.search_funcs[hash] = null;
		app.search_args[hash] = null;
	}
}

nwWIN.on('loaded', function() {
	nwWIN.showDevTools();

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
				el_result_container.prepend(el_result);
			}
		} else {
			var el_result_container = app.getElement("#search-results");
			app.clearElement(el_result_container);
		}
	})
	function selectSearchResult(hash_val) {
		app.search_funcs[hash_val].apply(this, app.search_args[hash_val]);
		app.getElement("#search-input").value = "";
		app.clearElement(app.getElement("#search-results"));

		// move found value up in list
		app.search_hashvals = app.search_hashvals.filter(e => e != hash_val);
		app.search_hashvals.unshift(hash_val);
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
					selected_index += 1;
				else
					selected_index -= 1;

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

	dispatchEvent("ideReady");

	app.openProject("src/projects/penguin");

	//(new MapEditor()).load('');
});