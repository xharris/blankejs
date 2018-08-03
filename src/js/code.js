var font_size = 16;
var object_list = {}
var object_src = {};
var object_instances = {};

var autocomplete, re_class, re_class_list, re_class_and_instance, hints, re_instance, callbacks;

function reloadCompletions() {
	delete require.cache[require.resolve('./autocomplete.js')];
	autocomplete = require('./autocomplete.js');

	re_class = autocomplete.class_regex;
	re_class_list = null;
	if (autocomplete.class_list)
		re_class_list = '^('+autocomplete.class_list.join('|')+')';
	hints = autocomplete.completions;
	re_instance = autocomplete.instance_regex;

	re_class_and_instance = Object.assign({}, re_class);
	for (let c in re_instance) {
		if (!re_class_and_instance[c])
			re_class_and_instance[c] = re_instance[c];
	}

	callbacks = {};
	for (let htype in hints) {
		for (let prop of hints[htype]) {
			if (prop.callback) {
				if (!callbacks[htype]) callbacks[htype] = [];
				callbacks[htype].push(prop.fn);
			}
		}
	}
}

function refreshObjectList (filename, content) {
	// should a server be running?
	if (!app.isServerRunning() && content.includes("Net.")) {								
		app.runServer();
	}

	// remove from whole list
	let obj_string = object_src[filename] || '';
	for (let category in object_list) {
		if (!object_list[category]) object_list[category] = {}

		let objects = object_list[category];
		if (object_instances[filename] && object_instances[filename][category])
			object_instances[filename][category] = [];

		for (let obj_name in objects) {
			let occurences = obj_string.split(obj_name).length - 1;
			if (occurences > 0) {
				object_list[category][obj_name] -= occurences;
				if (object_list[category][obj_name] == 0)
					delete object_list[category][obj_name];
			}
		}
	}

	// clear src list
	object_src[filename] = '';

	function iterateRegex (regex_list) {
		let ret_matches = [];

		for (var category in regex_list) {
			let re = regex_list[category];
		
			ret_matches = [];
			if (re) {
				if (Array.isArray(re)) {
					for (let subre of re) {
						let matches = [];
						do {
							matches = subre.exec(content);
							if (matches) {
								ret_matches.push(matches[1]);
							}
						} while (matches && matches.length);
					}
				} else {
					let matches = [];
					do {
						matches = re.exec(content);
						if (matches) {
							ret_matches.push(matches[1]);
						}
					} while (matches && matches.length);
				}
			}

			// if (ret_matches.length == 0) continue;
			for (let o in ret_matches) {
				let obj_name = ret_matches[o];
				object_src[filename] += obj_name + ' ';

				// increment in whole list
				if (!object_list[category]) object_list[category] = {};
				if (object_list[category][obj_name])
					object_list[category][obj_name]++;
				else {
					object_list[category][obj_name] = 1;
				}
			}
		}
	}
	
	iterateRegex(re_class);
	iterateRegex(re_instance);

	for (let category in object_list) {
		for (let obj_name in object_list[category]) {
			// get instances made with those classes
			if (re_instance[category]) {
				var regex_instance = new RegExp(re_instance[category].source.replace('<class_name>', obj_name), re_instance[category].flags);
				var ret_instance_match;

				if(!object_instances[filename])
					object_instances[filename] = {};
				if(!object_instances[filename][category])
					object_instances[filename][category] = [];
				do {
					ret_instance_match = regex_instance.exec(content);
					if (!ret_instance_match) {
						// continue; // no longer usable after adding 'for (let obj_name of ret_matches)'
					}
					else if(!object_instances[filename][category].includes(ret_instance_match[1])) {
						object_instances[filename][category].push(ret_instance_match[1]);
					}

				} while (ret_instance_match)
			}
		}
	}
}

class Code extends Editor {
	constructor (...args) {
		super(...args);
		this.setupDragbox();

		var this_ref = this;
		
		this.file = '';
		this.script_folder = "/scripts";

		// create codemirror editor
		this.edit_box = document.createElement("textarea");
		this.edit_box.classList.add("code")
		this.appendChild(this.edit_box)

		var this_ref = this;
		CodeMirror.defineMode("blanke", function(config, parserConfig) {
		  var blankeOverlay = {
		    token: function(stream, state) {
				let baseCur = stream.lineOracle.state.baseCur;
				if (baseCur == null) baseCur = "";
				else baseCur += " ";
		    	var ch;
		
		    	blanke.cooldownFn("refreshObjectList", 500, function(){
		    		refreshObjectList(this_ref.file, this_ref.codemirror.getValue());
		    	});				    	

		      	// comment
		      	if (stream.match(/\s*--/) || baseCur.includes("comment")) {
		      		while ((ch = stream.next()) != null && !stream.eol());
		      		return "comment";
		      	}

		      	// class list (Draw, Asset, etc)
				if (re_class_list) {
					let match = stream.match(new RegExp(re_class_list));
					if (match) {
						return baseCur+"blanke-class blanke-"+match[1].toLowerCase();
					}
				}	

				// class instances
				for (let file in object_instances) {
					for (let category in object_instances[file]) {
			      		if (object_instances[file] && object_instances[file][category]) {
			      			for (var instance_name of object_instances[file][category]) {
			      				if (stream.match(new RegExp("^"+instance_name))) {
			      					return baseCur+"blanke-instance blanke-"+category+"-instance";
			      				}
			      			}
			      		}
			      	}
		      	}

				// user made classes (PlayState, Player)
		    	for (let category in object_list) {
			    	if (re_class[category]) {
						
			    		let re_obj_category = '^\\s(';
			    		for (let obj_name in object_list[category]) {
							re_obj_category += obj_name+'|';
			    		}

			    		if (Object.keys(object_list[category]).length > 0) {
			    			if (stream.match(new RegExp(re_obj_category.slice(0,-1)+')'))) {
					      		return baseCur+"blanke-class blanke-"+category;
				    		}
				    	}

				    }
				}

				// self keyword
		      	if (stream.match(/^self/g)) {
		      		return baseCur+"blanke-self";
		      	}

			    while (stream.next() && false) {}
			    return null;

				/* keeping this code since it's a good example
				if (stream.match("{{")) {
			      	while ((ch = stream.next()) != null)
			      		if (ch == "}" && stream.next() == "}") {
			      			stream.eat("}");
			      			return "blanke-test";
			      		}
		      	}
				*/	
		    }
		  };
		  return CodeMirror.overlayMode(CodeMirror.getMode(config, parserConfig.backdrop || "lua"), blankeOverlay);
		});

		this.codemirror = CodeMirror.fromTextArea(this.edit_box, {
			mode: "blanke",
			theme: "material",
            smartIndent : true,
            lineNumbers : true,
            lineWrapping : false,
            indentUnit : 4,
            tabSize : 4,
            indentWithTabs : true,
            highlightSelectionMatches: {showToken: /\w{3,}/, annotateScrollbar: true},
            matchBrackets: true,
            completeSingle: false,
            extraKeys: {
            	"Cmd-S": function(cm) {
            		this_ref.save();
            	},
            	"Ctrl-S": function(cm) {
            		this_ref.save();
            	},
            	"Ctrl-=": function(cm) {
            		font_size += 1;
            		this_ref.setFontSize(font_size);
            	},
            	"Ctrl--": function(cm) {
            		font_size -= 1;
            		this_ref.setFontSize(font_size);
            	},
            	"Ctrl-F": "findPersistent",
            	"Ctrl-Space": "autocomplete"
            }
		});

		this.autocompleting = false;
		this.last_word = '';
		this.codemirror.on("keyup", function(){
			let editor = this_ref.codemirror;
			let cursor = editor.getCursor();

			let word_pos = editor.findWordAt(cursor);
			let word = editor.getRange(word_pos.anchor, word_pos.head);
			let before_word_pos = {line: word_pos.anchor.line, ch: word_pos.anchor.ch-1};
			let before_word = editor.getRange(before_word_pos, {line:before_word_pos.line, ch:before_word_pos.ch+1});
			let word_slice = word.slice(-1);

			// get the activator used
			let comp_activators = [':','.'];
			let activator = before_word;
			if (comp_activators.includes(word_slice))
				activator = word_slice;

			let token_pos = {line: cursor.line, ch: cursor.ch-1};
			if (comp_activators.includes(before_word) && !comp_activators.includes(word)) {
				token_pos.ch = before_word_pos.ch - 1;
			}
       		let token_type = editor.getTokenTypeAt(token_pos) || '';

			//if ((comp_activators.includes(word_slice) || comp_activators.includes(before_word.slice(-1))) && !this_ref.autocompleting) {
				this_ref.autocompleting = true;
			//}

			if (this_ref.autocompleting && this_ref.last_word != word) {
				this_ref.last_word = word;
				function containsTyped(str) {
					if (str == word) return false;
					if (word_slice == activator) return true;
					else return str.startsWith(word);
				}

				function globalActivator() {
					return (word.trim() != '' && !comp_activators.includes(activator));
				}

				let hint_list = [];
				let list = [];
				let hint_types = {};

				// token can have multiple types
				let types = token_type.split(' ');

				// get most recent callback token type
				if (types.includes("blanke-self")) {
					let loop = token_pos.line-1;
					do {
						let tokens = editor.getLineTokens(loop);
						for (var t of tokens) {
							if (t.type && t.type.includes("blanke-class")) {
								let class_type = t.type.split(" ").slice(-1)[0];
								let line = editor.getLine(loop);

								if (callbacks[class_type]) {
									for (let cb of callbacks[class_type]) {
										if (line.includes(":"+cb)) {
											let self_ref = autocomplete.self_reference[class_type];
											if (self_ref == "class") 
												types = ["blanke-class", class_type];
											else if (self_ref == "instance")
												types = ["blanke-instance", class_type+"-instance"];

											if (self_ref)
												token_type = types.join(' ');

											loop = 0;
										}
									}
								}
							}
						}
						loop--;
					} while (loop > 0);
				}

				for (let t of types) {
					Array.prototype.push.apply(hint_list, hints[t] || []);
				}

				// add global hints
				if (!hint_list && hints.global) {
					hint_list = [];
					for (let h = 0; h < hints.global.length; h++) {
						hints.global[h].global = true;
						hint_list.push(hints.global[h]);
					}
				}

				for (var o in hint_list) {
					let hint_opts = hint_list[o];
					let arg_info = "";

					let text, render, add = false;

					// get the item type
					let item_type = '';
					if (hint_opts.fn) {
						if (hint_opts.callback)
							item_type = 'cb';
						else
							item_type = 'fn';
					} else if (hint_opts.prop) {
						item_type = 'var';
					}

					if (hint_opts.fn && 
						(
							(hint_opts.global && globalActivator()) || 
							(activator == ':' && !hint_opts.global && (token_type.includes('instance') || hint_opts.callback)) || 
							(activator == '.' && !hint_opts.global && !hint_opts.callback && !token_type.includes('instance'))
						) && containsTyped(hint_opts.fn)
					) {
						text = hint_opts.fn;
						hint_types[text] = 'function1';
						if (hint_opts.vars) {
							for (var arg in hint_opts.vars) {
								if (hint_opts.vars[arg] != "")
   								arg_info += arg + " : " + hint_opts.vars[arg] + "<br/>";
							}
						}

						function specialReplacements(value, index, array) {
							if (value == 'etc') return '<span class="grayed-out">...</span>';
							return value;
						}
						let paren = ["(",")"];
						if (hint_opts.named_args) {
							paren = ["{","}"];
							hint_types[text] = 'function2';
						}
						render = hint_opts.fn + paren[0] + Object.keys(hint_opts.vars || {}).map(specialReplacements) + paren[1] +
									"<p class='prop-info'>"+(hint_opts.info || '')+"</p>"+
									"<p class='arg-info'>"+arg_info+"</p>"+
									"<p class='item-type'>"+item_type+"</p>";
						add = true;
					}
					if (hint_opts.prop && 
						((activator == '.' && !hint_opts.global) || (hint_opts.global && globalActivator())) && 
						!hint_opts.callback && containsTyped(hint_opts.prop)) {
						text = hint_opts.prop;
						hint_types[text] = 'property';
						render = hint_opts.prop + "<p class='prop-info'>"+(hint_opts.info || '')+"</p>"+
									"<p class='item-type'>"+item_type+"</p>";
						add = true;
					}
					if (add) {
						list.push({
							text:text,
							render:function(el, editor, data) { el.innerHTML = render }
						});
					}
				}
				blanke.cooldownFn("editor_show_hint", 250, function(){
					editor.showHint({
						hint: function(cm) {
							let completions = {
								from: editor.getDoc().getCursor(),
								to: editor.getDoc().getCursor(),
								list: list
							};

							CodeMirror.on(completions, 'pick', function(completion){
								let comp_word = editor.findWordAt(editor.getCursor());
								if (hint_types[completion.text] == 'property')
									editor.replaceRange(completion.text, comp_word.anchor, comp_word.head);
								else if (hint_types[completion.text] == 'function1')
									editor.replaceRange(completion.text+'(', comp_word.anchor, comp_word.head);
								else if (hint_types[completion.text] == 'function2')
									editor.replaceRange(completion.text+'{', comp_word.anchor, comp_word.head);
							});

							return completions
						},
						completeSingle: false
					});
				});
			}
		});

		this.setFontSize(font_size);
		//this.codemirror.setSize("100%", "100%");
		this.codemirror.on('change', function(cm, obj){
			this_ref.addAsterisk();
		});
		this_ref.codemirror.refresh();
		this.addCallback('onResize', function(w, h) {
			this_ref.codemirror.refresh();
		});
		// prevents user from saving a million times by holding the button down
		/*document.addEventListener('keyup', function(e){
			if (e.key == "s" && e.ctrlKey) {
				this_ref.save();
        		this_ref.removeAsterisk();
			}
		});*/

		// tab click
		this.setOnClick(function(self){
			(new Code(app)).edit(self.file);
			this_ref.setFontSize(font_size);
		}, this);
	}

	addAsterisk () {
		this.setSubtitle("*");
	}

	removeAsterisk() {
		this.setSubtitle();
	}

	setFontSize (num) {
		font_size = num;
		this.codemirror.display.wrapper.style['line-height'] = (font_size-2).toString()+"px";
		this.codemirror.display.wrapper.style.fontSize = font_size.toString()+"px";
		this.codemirror.refresh();
	}

	onMenuClick (e) {
		var this_ref = this;
		app.contextMenu(e.x, e.y, [
			{label:'rename', click:function(){this_ref.renameModal()}},
			{label:'delete', click:function(){this_ref.deleteModal()}}
		]);
	}

	edit (file_path) {
		var this_ref = this;

		this.file = file_path;
		var text = nwFS.readFileSync(file_path, 'utf-8');

		this.codemirror.setValue(text);
		this.codemirror.clearHistory();
		this.codemirror.refresh();

		this.setTitle(nwPATH.basename(file_path));
		this.removeAsterisk();
		refreshObjectList(this.file, this.codemirror.getValue());
	}

	save () {
		let this_ref = this;
		blanke.cooldownFn("codeSave", 200, function(){
			nwFS.writeFileSync(this_ref.file, this_ref.codemirror.getValue());
			refreshObjectList(this_ref.file, this_ref.codemirror.getValue());
			this_ref.removeAsterisk();
		});
	}

	delete (path) {
		nwFS.unlink(path);

		if (this.file == path) {
			this.close();
		}
	}

	deleteModal () {
		var name = this.file;
		if (name.includes('main.lua')) {
			blanke.showModal(
				"You cannot delete \'"+name+"\'",
			{
				"oops": function() {}
			});
		} else {
			var this_ref = this;
			blanke.showModal(
				"delete \'"+name+"\'",
			{
				"yes": function() { this_ref.delete(name); },
				"no": function() {}
			});
		}
	}

	rename (old_path, new_path) {
		var this_ref = this;
		nwFS.readFile(new_path, function(err, data){
			if (err) { // if there's an error, the file doesn't already exist and therefore renaming can continue
				nwFS.rename(old_path, new_path);
				this_ref.file = new_path;
				this_ref.setTitle(nwPATH.basename(this_ref.file));
			}
		});
	}

	renameModal () {
		var filename = this.file;

		if (nwPATH.basename(filename) == 'main.lua') {
			blanke.showModal(
				"You cannot rename \'"+nwPATH.basename(filename)+"\'",
			{
				"oh yea I forgot": function() {}
			});
		} else {
			var this_ref = this;
			blanke.showModal(
				"<label>new name: </label>"+
				"<input class='ui-input' id='new-file-name' style='width:100px;' value='"+nwPATH.basename(filename, nwPATH.extname(filename))+"'/>",
			{
				"yes": function() { 
					let new_path = nwPATH.join(nwPATH.dirname(filename), app.getElement('#new-file-name').value+".lua");
					this_ref.rename(filename, new_path);
				},
				"no": function() {}
			});
		}
	}
}

document.addEventListener('fileChange', function(e){
	// if (e.detail.type == 'change') {
		app.removeSearchGroup("Code");
		addScripts(app.project_path);
	// }
});

function addScripts(folder_path) {
	var file_list = [];
	nwFS.readdir(folder_path, function(err, files) {
		if (err) return;
		files.forEach(function(file){
			var full_path = nwPATH.join(folder_path, file);
			nwFS.stat(full_path, function(err, file_stat){		
				// iterate through directory			
				if (file_stat.isDirectory()) 
					addScripts(full_path);

				// add file to search pool
				else if (file.endsWith('.lua')) {
					nwFS.readFile(full_path, 'utf-8', function(err, data){
						if (!err) {
							refreshObjectList(full_path, data);
						}
					});

					app.addSearchKey({
						key: file,
						onSelect: function(file_path){
							if (!DragBox.focus(nwPATH.basename(file_path)))
								(new Code(app)).edit(file_path);
						},
						tags: ['script'],
						args: [full_path],
						group: 'Code'
					});
				}
			});
		});
	});
}

document.addEventListener("closeProject", function(e){	
	app.removeSearchGroup("Code");
});

document.addEventListener("openProject", function(e){
	
	reloadCompletions();
	// reload completions on file change
	nwFS.watchFile('src/autocomplete.js', function(e){
		reloadCompletions();
		blanke.toast("autocomplete reloaded!");
	});

	var proj_path = e.detail.path;
	app.removeSearchGroup("Code");
	addScripts(proj_path);

	app.addSearchKey({
		key: 'Create script',
		onSelect: function() {
			var script_dir = nwPATH.join(app.project_path,'scripts');
			nwFS.stat(script_dir, function(err, stat) {
				if (err) nwFS.mkdirSync(script_dir);
				// overwrite the file if it exists. fuk it!!
				nwFS.readdir(script_dir, function(err, files){
					nwFS.writeFile(nwPATH.join(script_dir, 'script'+files.length+'.lua'),"\
-- create an Entity: BlankE.addEntity(\"Player\");\n\n\
-- create a State: BlankE.addState(\"HouseState\");\
					", function(err){
						if (!err) {
							// edit the new script
							(new Code(app)).edit(nwPATH.join(script_dir, 'script'+files.length+'.lua'));
						}
					});

				});
			});
		},
		tags: ['new']
	});
});
