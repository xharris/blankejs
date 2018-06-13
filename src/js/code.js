var font_size = 16;
var object_list = {}
var object_src = {};
var object_instances = {};

var autocomplete, re_objects, hints, re_instance;

function reloadCompletions() {
	delete require.cache[require.resolve('./autocomplete.js')];
	autocomplete = require('./autocomplete.js');

	re_objects = autocomplete.class_regex;
	hints = autocomplete.completions;
	re_instance = autocomplete.instance_regex;
}

function refreshObjectList (filename, content) {
	let ret_matches = [];
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
	do {
		for (var category in re_objects) {
			let re = re_objects[category];
		
			ret_matches = [];
			if (Array.isArray(re)) {
				for (let subre of re) {
					let matches = subre.exec(content);
					if (matches) {
						ret_matches.push(matches[1]);
					}
				}
			} else {
				let matches = re.exec(content);
				if (matches) {
					ret_matches.push(matches[1]);
				}
			}


			if (ret_matches.length == 0) continue;

			for (let obj_name of ret_matches) {
				object_src[filename] += obj_name + ' ';

				// increment in whole list
				if (!object_list[category]) object_list[category] = {};
				if (object_list[category][obj_name])
					object_list[category][obj_name]++;
				else {
					object_list[category][obj_name] = 1;

				}

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
						else if(!object_instances[filename][category].includes(ret_instance_match[1]))
							object_instances[filename][category].push(ret_instance_match[1]);
					} while (ret_instance_match)
				}
			}
		}
	} while (ret_matches.length);
}

class Code extends Editor {
	constructor (...args) {
		super(...args);
		this.setupTab();

		var this_ref = this;
		
		this.file = '';
		this.script_folder = "/scripts";
		this.can_save = true;

		// create codemirror editor
		this.edit_box = document.createElement("textarea");
		this.edit_box.classList.add("code")
		this.appendChild(this.edit_box)

		var this_ref = this;

		CodeMirror.defineMode("blanke", function(config, parserConfig) {
		  var blankeOverlay = {
		    token: function(stream, state) {
		      var ch;

		      var break_bool = 0;

		      // keeping this code since it's a good example
		      if (stream.match("{{")) {
		        while ((ch = stream.next()) != null)
		          if (ch == "}" && stream.next() == "}") {
		            stream.eat("}");
		            return "blanke-test";
		          }
		      }
		      break_bool *= !stream.match('{',false);

		      var class_names = ['State','Entity']

		      // check for user-made classes
		      for (var category in re_objects) {
			      if (object_list[category]) {
			      	for (var obj_name in object_list[category]) {
			      		let is_match = stream.match(obj_name,true);
			      		if (is_match) {
			      			return "blanke-"+category;
			      		}
			      		break_bool *= !is_match;
			      	}

			      	if (object_instances[this_ref.file] && object_instances[this_ref.file][category]) {
				      	for (var instance_name of object_instances[this_ref.file][category]) {
				      		let is_match = stream.match(instance_name,true);
				      		if (is_match) {
				      			return "blanke-"+category+"-instance";
				      		}
				      		break_bool *= !is_match;
				      	}
			      	}	
			      }
		      }



		      while (stream.next() && break_bool) {}
		      return null;
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
            		this_ref.can_save = false;
            		this_ref.removeAsterisk();
            	},
            	"Ctrl-S": function(cm) {
            		this_ref.save();
            		this_ref.can_save = false;
            		this_ref.removeAsterisk();
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

			// get the activator used
			let comp_activators = [':','.'];
			let activator = before_word;
			if (comp_activators.includes(word))
				activator = word;

			let token_pos = {line: cursor.line, ch: cursor.ch-1};
			if (comp_activators.includes(before_word) && !comp_activators.includes(word)) {
				token_pos.ch = before_word_pos.ch - 1;
			}
       		let token_type = editor.getTokenTypeAt(token_pos);

			if ((comp_activators.includes(word) || comp_activators.includes(before_word)) && !this_ref.autocompleting) {
				this_ref.autocompleting = true;
			}

			if (this_ref.autocompleting && this_ref.last_word != word) {
				this_ref.last_word = word;
				function containsTyped(str) {
					console.log(word);
					if (str == word) return false;
					if (word == activator) return true;
					else return str.startsWith(word);
				}

				let hint_list = hints[token_type];
				let list = [];
				let hint_types = {};
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
						((activator == ':' && (token_type.includes('instance') || hint_opts.callback)) || (activator == '.' && !hint_opts.callback && !token_type.includes('instance'))) && 
						containsTyped(hint_opts.fn)
					) {
						text = hint_opts.fn;
						hint_types[text] = 'function';
						if (hint_opts.vars) {
							for (var arg in hint_opts.vars) {
								if (hint_opts.vars[arg] != "")
   								arg_info += arg + " : " + hint_opts.vars[arg] + "<br/>";
							}
						}
						render = hint_opts.fn + "(" + Object.keys(hint_opts.vars || {}) + ")"+
									"<p class='arg-info'>"+arg_info+"</p>"+
									"<p class='item-type'>"+item_type+"</p>";
						add = true;
					}
					if (hint_opts.prop && activator == '.' && !hint_opts.callback && containsTyped(hint_opts.prop)) {
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
				if (Object.keys(hints).includes(token_type)) {
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
								else if (hint_types[completion.text] == 'function')
									editor.replaceRange(completion.text+'(', comp_word.anchor, comp_word.head);
							});

							return completions
						},
						completeSingle: false
					});
				}
			}
		});

		this.setFontSize(font_size);
		//this.codemirror.setSize("100%", "100%");
		this.codemirror.on('change', function(){
			this_ref.addAsterisk();
			refreshObjectList(this_ref.file, this_ref.codemirror.getValue());
		});
		this_ref.codemirror.refresh();
		this.addCallback('onResize', function(w, h) {
			this_ref.codemirror.refresh();
		});
		// prevents user from saving a million times by holding the button down
		document.addEventListener('keyup', function(e){
			if (e.key == "s" && e.ctrlKey) {
				this_ref.can_save = true;
			}
		});

		// tab click
		this.setOnClick(function(self){
			(new Code(app)).edit(self.file);
		}, this);

	}

	addAsterisk () {
		this.setTitle(nwPATH.basename(this.file)+"*");
	}

	removeAsterisk() {
		this.setTitle(nwPATH.basename(this.file));
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
		refreshObjectList(this.file, this.codemirror.getValue());
	}

	save () {
		if (this.can_save) {
			nwFS.writeFileSync(this.file, this.codemirror.getValue());
			this.can_save = false;
		}
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

	rename (old_path, new_name) {
		var this_ref = this;
		nwFS.readFile(nwPATH.dirname(this.file)+"/"+new_name, function(err, data){
			if (err) {
				nwFS.rename(old_path, nwPATH.dirname(this_ref.file)+"/"+new_name);
				this_ref.file = nwPATH.dirname(this_ref.file)+"/"+new_name;
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
				"yes": function() { this_ref.rename(filename, app.getElement('#new-file-name').value+".lua"); },
				"no": function() {}
			});
		}
	}
}

document.addEventListener('fileChange', function(e){
	if (e.detail.type == 'change') {
		app.removeSearchGroup("Code");
		addScripts(app.project_path);
	}
});

function addScripts(folder_path) {
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
							if (!Tab.focusTab(nwPATH.basename(file_path)))
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

document.addEventListener("openProject", function(e){
	
	reloadCompletions();
	// reload completions on file change
	nwFS.watchFile('src/autocomplete.js', function(e){
		reloadCompletions();
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
-- create an Entity: BlankE.addClassType(\"Player\", \"Entity\");\n\n\
-- create a State: BlankE.addClassType(\"houseState\", \"State\");\
					");

					// edit the new script
					(new Code(app)).edit(nwPATH.join(script_dir, 'script'+files.length+'.lua'));
				});
			});
		},
		tags: ['new']
	});
});
