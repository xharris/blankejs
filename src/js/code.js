/* list of changes
	re_class_list: removed ^ at beginning
	changed order in defineMode: instance > class_list
*/
var re_add_sprite = /this\.addSprite\s*\(\s*['"][\w\s\/.-]+['"]\s*,\s*{[\s\w"',:]*image\s*:\s*['"]([\w\s\/.-]+)['"]/;
var re_new_sprite = /new\s+Sprite[\s\w{(:"',]+image[\s:]+['"]([\w\s\/.-]+)/;
var re_sprite_align = /sprite_align\s*=\s*[\"\']([\s\w]+)[\"\']/;
var re_sprite_pivot_single = /sprite_pivot\.(x|y)\s*\=\s*(\d+)/;
var re_sprite_pivot = /sprite_pivot\.set\(\s*(\d+)\s*,\s*(\d+)\s*\)/;


var code_instances = {};

var CODE_ASSOCIATIONS = [
	[
		/\bScene\s*\(\s*[\'\"](.+)[\'\"]/,
		"scene"
	],[
		/(\w+)\s+extends\s+Entity\s*/,
		"entity"
	],
];

var ext_class_list = {};// class_extends (Player)
var instance_list = {}; // instance (let player = new Player())
var var_list = {};      // user_words (let player;)
var class_list = []     // class_list (Map, Scene, Effect)
var keywords = [];
var this_lines = {};	// { file: {line_text : token_type (blanke-entity-instance) } }

var autocomplete, hints;
var re_class_extends, re_instance, re_user_words, re_image, re_this;

function isReservedWord(word) {
	return keywords.includes(word) || autocomplete.class_list.includes(word);
}

// called when autocomplete.js is modified
var reloadCompletions = () => {
    // get regex from autocomplete.js
    autocomplete = app.autocomplete;

	let plugin_ac = Plugins.getAutocomplete();
	for (let p in plugin_ac) {
		addCompletions(plugin_ac[p]);
	}

    re_class_extends = autocomplete.class_extends || {};
    re_instance = autocomplete.instance || {};
    re_user_words = autocomplete.user_words || {};
	keywords = autocomplete.keywords || [];
	hints = autocomplete.hints || {};
	class_list = autocomplete.class_list || [];
	re_image = autocomplete.image || [];
	re_this = autocomplete.this_ref || {};

	// add classes as globals if they have properties
	for (let c of class_list) {
		if (hints['blanke-'+c.toLowerCase()] && !hints.global.find(p => p.prop == c || p.fn == c))
			hints.global.push({ prop: c });
	}
}

document.addEventListener('loadedPlugins', reloadCompletions);

var addCompletions = (data) => {
	// add plugin autocomplete
	let update = (old_obj, new_obj, key) => {
		if (key == null) {
			// iterate keys of new_obj and put them in old_obj
			for (let k in new_obj) {
				update(old_obj, new_obj, k);
			}
		} else {
			if (!Array.isArray(old_obj[key]) && typeof old_obj[key] == 'object') {
				// go one level deeper
				for (let k in new_obj[key]) {
					update(old_obj[key], new_obj[key], k);
				}
			}
			else {
				// concat new_obj value to old_obj
				if (Array.isArray(old_obj[key])) {
					old_obj[key] = old_obj[key].concat(new_obj[key]);
				} else if (!old_obj[key]) {
					// completely new value, add it to old_obj
					old_obj[key] = new_obj[key];
				}
			}
		}
	}
	update(autocomplete, data);
}

var getCompletionList = (_type) => {
    let retrieve = (obj) => {
        let ret_obj = {};
        // do you like loops??
        for (let file in obj) {
            for (let cat in obj[file]) {
				if (!ret_obj[cat])
                	ret_obj[cat] = [];
                for (let name of obj[file][cat]) {
                    if (!ret_obj[cat].includes(name)) {
                        ret_obj[cat].push(name);
                    }
                }
            }
        }
		return ret_obj;
    }
    let arrays = {
        'ext-class':ext_class_list,
        'instance': instance_list,
        'var':      var_list,
        'class':    class_list      // array
    }
	let ret_val = arrays[_type];
    if (ret_val) {
		if (Array.isArray(ret_val))
			return ret_val
        return retrieve(ret_val);
    }
}

// ** called when a file is modified
var script_list = [];
var getKeywords = (file, content) => {
	if (file.includes('main.js')) return; // main.js makes while loop freeze for some reason
    blanke.cooldownFn('getKeywords.'+file, 500, ()=>{
        ext_class_list[file] = {};
        instance_list[file] = {};
        var_list[file] = {};

        // should a server be running?
		dispatchEvent('script_modified',{path:file, content:content})

        let match = (regex_obj, store_list) => {
			// refresh matches for all files
			for (let _file of script_list) {
				let data = (file == _file) ? content : nwFS.readFileSync(_file,'utf-8');
				for (let cat in regex_obj) {
					let regex = [].concat(regex_obj[cat])
					if (!store_list[_file])
						store_list[_file] = {};

					// clear old list of results
					if (!store_list[_file][cat])
						store_list[_file][cat] = [];
					let _match;
					for (let re of regex) {
						while (_match = re.exec(data)) {
							if (!store_list[_file][cat].includes(_match[1]))
								store_list[_file][cat].push(_match[1]);
						}
						
					}
            	}
			}
        }
        // start scanning
        ext_class_list[file] = {};
        match(re_class_extends, ext_class_list);        // user-made classes
        instance_list[file] = {};
        // add user class regexes
        let new_re_instance = {};
        for (let cat in re_instance) {
            new_re_instance[cat] = [];
			let re_list = [].concat(re_instance[cat]);
            for (let re of re_list) {
                if (re.source.includes('<class_name>')) { 
                    // YES - make the replacement
					let ext_classes = getCompletionList('ext-class')[cat];
                    if (ext_classes) {
                        // iterate user-made classes
                        for (let class_name of ext_classes) {
							if (!new_re_instance[class_name])
								new_re_instance[class_name] = [];
                            new_re_instance[class_name].push(new RegExp(re.source.replace('<class_name>', class_name), re.flags))
                        }
                    }
                } else {
                    // NO - add current regex
                    new_re_instance[cat].push(re);
                }
            }
        }
        match(new_re_instance, instance_list);
        var_list[file] = {};
		match(re_user_words, var_list);

		// for 'this' keyword
		this_lines[file] = {};
		for (let name in re_this) {
			let regexs = [].concat(re_this[name]);
			for (let re of regexs) {
				let match;
				while (match = re.exec(content)) {
					this_lines[file][match[0].trim()] = [name].concat(match.slice(1));
				}
			}
		}
    });
}

class Code extends Editor {
	constructor () {
		super();
		this.setupFibWindow();
		var this_ref = this;
		this.file = '';
		this.script_folder = "/scripts";
		this.file_loaded = false;

		if (!app.settings.code) app.settings.code = {};
		ifndef_obj(app.settings.code, {
			font_size:16
		});

		this.editors = [];
		this.function_list = [];
		this.breakpoints = {};

		// create codemirror editor
		this.edit_box = app.createElement("div","code");
		this.appendChild(this.edit_box);

		// box to show last viewed function (until ')' is pressed?)
		this.el_fn_helper = app.createElement('div',['fn-helper','hidden']);
		this.el_fn_helper.addEventListener("mouseenter",function(){
			this_ref.refreshFnHelperTimer();
		});
		this.appendChild(this.el_fn_helper);
		this.fn_helper_timer = null;

		// class method list
		this.el_class_methods = app.createElement("div","methods");
		this.appendChild(this.el_class_methods);

		// add game preview
		this.game = new GamePreview(null,{ ide_mode: true });
		
		this.console = new Console();
		this.console.appendTo(this.getContent());
		this.getContainer().bg_first_only = true;
		this.appendBackground(this.game.container);
		
		this.game.size = this.container.getSizeType();

		var this_ref = this;
		CodeMirror.defineMode("blanke", (config, parserConfig) => {
			var blankeOverlay = {
				token: (stream, state) => {
					let baseCur = stream.lineOracle.state.baseCur;
					let line = stream.lineOracle.line;
					if (baseCur == null) baseCur = "";
					else baseCur += " ";
					var ch;

					getKeywords(this_ref.file, this_ref.codemirror.getValue());

					// comment
					if (stream.match(/\s*\/\//) || baseCur.includes("comment")) {
						while ((ch = stream.next()) != null && !stream.eol());
						return "comment";
					}

					let instances = getCompletionList('instance');
					let ext_classes = getCompletionList('ext-class');
					let classes = getCompletionList('class');

					// instance
					for (let cat in instances) { // Player, Map
						for (let name of instances[cat]) { // player1, map1
							// get parent class name
							let parent = '';
							for (let p in ext_classes) {
								if (ext_classes[p].includes(cat))
									parent = `blanke-${p.toLowerCase()}-instance`;
							}
							if (stream.match(new RegExp("^"+name))) 
								return baseCur+`blanke-instance ${parent} blanke-${cat.toLowerCase()}-instance`;
						}
					}

					// extended classes
					for (let cat in ext_classes) { // entity
						for (let name of ext_classes[cat]) { // Player
							if (stream.match(new RegExp("^"+name))) 
								return baseCur+`blanke-class blanke-${cat.toLowerCase()}`;
						}
					}

					// regular classes
					for (let name of classes) { // Map, Scene
						if (stream.match(new RegExp("^"+name))) 
							return baseCur+`blanke-class blanke-${name.toLowerCase()}`;
					}


					while (stream.next() && false) {}
					return null;
				}
			};
			return CodeMirror.overlayMode(CodeMirror.getMode(config, parserConfig.backdrop || "javascript"), blankeOverlay);
		});

		let showSpritePreview = (image_name, include_img, cb) => {
			let spr_prvw = new SpritesheetPreview(image_name);
			spr_prvw.onCopyCode = function(vals){
				let args = {};
				args.image = '\"'+app.cleanPath(vals.image.replace(/.*[\/\\](.*)\.\w+/g,"$1"))+'\"';
				args.frames = vals.frames;
				args.speed = vals.speed;

				let optional = ['frame_size','border','offset'];
				for (let opt of optional) {
					if (vals[opt].reduce((s,n)=>s+n) > 0)
						args[opt] = "["+vals[opt].join(',')+"]"
				}
				let arg_str = '';
				
				if (include_img)
					arg_str += '\"'+(vals.name == '' || !vals.name ? 'my_animation' : vals.name)+'\", ';
				arg_str += '{';
				for (let key in args) {
					arg_str += (key+":"+args[key]+", ");
				}
				arg_str = arg_str.slice(0,-2) + '}';
				if (cb) cb(arg_str, vals.name);
			}
		}

		this.gutterEvents = {
			'\.addSpr':{
				name:'sprite',
				tooltip:'make a spritesheet animation',
				fn:function(line_text, cm, cur){		
					// get currently used image name
					let image_name = '';
					if (image_name = line_text.match(re_add_sprite)) 
						image_name = image_name[1]
					showSpritePreview(image_name, true, (arg_str) => { 
						line_text = line_text.replace(/(\s*)(\w+).addSpr.*/g,"$1$2.addSprite("+arg_str+")");
						this_ref.codemirror.replaceRange(line_text,{line:cur.line,ch:0}, {line:cur.line,ch:10000000});
					});
				}
			},
			'new\\s+Sprite':{
				name:'sprite',
				tooltip:'make a spritesheet animation',
				fn:function(line_text, cm, cur){
					// get currently used image name
					let image_name = '';
					if (image_name = line_text.match(re_new_sprite)) 
						image_name = image_name[1]
					showSpritePreview(image_name, false, (arg_str, image_name) => {
						line_text = line_text.replace(/Sprite.*/g,"Sprite("+arg_str+")");
						this_ref.codemirror.replaceRange(line_text,{line:cur.line,ch:0}, {line:cur.line,ch:10000000});
					})
				}
			}
		}

		this.autocompleting = false;
		this.last_word = '';

		this.setupEditor(this.edit_box);

		this.addCallback('onFocus', function() {
			this_ref.game.size = this_ref.container.getSizeType();
			this_ref.refreshGame();
		});

		this.addCallback('onResize', function(w, h) {
			this_ref.game.size = this_ref.container.getSizeType();
			
			if (!this_ref.container.in_background)
				this_ref.console.clear();

			// move split view around if there is one
			let content_area = this_ref.getContent();
			content_area.classList.remove("horizontal","vertical");
			if (w > h) content_area.classList.add("horizontal");
			if (h > w) content_area.classList.add("vertical");

			this_ref.codemirror.refresh();
		});

		this.game.onError = (msg, file, lineNo, columnNo) => {
			this.disableFnHelper();
			let file_link = `<a href='#' onclick="Code.openScript('${file}',${lineNo})">${nwPATH.basename(file)}</a>`;
			this.console.err(`${file_link} (&darr;${lineNo}&rarr;${columnNo}): ${msg}`);
		}
		this.game.onLog = (...msgs) => {
			if (this.container.in_background)
				this.console.log(...msgs);
		}
		this.game.onRefresh = () => {
			this.console.clear();
			this.enableFnHelper();
			this.codemirror.focus();
		}

		this.addCallback('onEnterView',()=>{
			this.game.resume();
		});
		this.addCallback('onExitView',()=>{
			this.game.pause();
		});

		this.codemirror.refresh();

		// prevents user from saving a million times by holding the button down
		/*document.addEventListener('keyup', function(e){
			if (e.key == "s" && e.ctrlKey) {
				this_ref.save();
        		this_ref.removeAsterisk();
			}
		});*/

		/* tab click
		this.setOnClick(function(self){
			Code.openScript(self.file);
			this_ref.setFontSize(font_size);
		}, this);
		*/
	}

	setupEditor(el_container) {
		let this_ref = this;
		let new_editor = CodeMirror(el_container, {
			mode: "blanke",
			theme: "material",
            smartIndent : true,
            lineNumbers : true,
            gutters:["CodeMirror-linenumbers","breakpoints",...Object.values(this.gutterEvents).map(v=>v.name).filter((v,k,a)=>a.indexOf(v)===k)],
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
					cm.focus();
            	},
            	"Ctrl-S": function(cm) {
            		this_ref.save();
            	},
            	"Ctrl-=": function(cm) { this_ref.fontSizeUp(); },
            	"Ctrl--": function(cm) { this_ref.fontSizeDown(); },
            	"Cmd-=": function(cm) { this_ref.fontSizeUp(); },
            	"Cmd--": function(cm) { this_ref.fontSizeDown(); },
            	"Shift-Tab": "indentLess",
            	"Ctrl-F": "findPersistent",
            	"Ctrl-Space": "autocomplete"
            }
		});

		new_editor.on('gutterClick',(cm, n, gutter) => {

				let info = cm.lineInfo(n);
				let containers = {'(':')', '[':']', '{':'}'};
				for (let open in containers) {
					if ((info.text.match(new RegExp(`\\${open}`,'g')) || []).length != 
						(info.text.match(new RegExp(`\\${containers[open]}`,'g')) || []).length)
						return;
				}
				let marker = blanke.createElement("div");
				marker.innerHTML=`<i class="breakpoint">&#10148;</i>`;
				let enable = !info.gutterMarkers || !info.gutterMarkers.breakpoints;
				cm.setGutterMarker(n, "breakpoints", enable ? marker : null);

				if (enable) 
					this.breakpoints[n] = true;
				else
					delete this.breakpoints[n];
		});
		
		// set up events
		//this.codemirror.setSize("100%", "100%");
		function checkGutterEvents(cm, obj) {
			blanke.cooldownFn('checkGutterEvents',1000,()=>{
				let cur = cm.getCursor();
				let line_text = cm.getLine(cur.line);
	
				Object.values(this_ref.gutterEvents).forEach(v => {
					cm.clearGutter(v.name);
				})
				
				for (let txt in this_ref.gutterEvents) {
					let info = this_ref.gutterEvents[txt];
					if (line_text.match(new RegExp(txt))) {
						let el_gutter = blanke.createElement('div','gutter-evt');
						el_gutter.innerHTML="<i class='mdi mdi-flash'></i>";
						if (info.tooltip)
							el_gutter.title = info.tooltip;
						el_gutter.addEventListener('click',function(e){
							this_ref.gutterEvents[txt].fn(line_text, cm, cur);
						});
						cm.setGutterMarker(cur.line, info.name, el_gutter);
						
					}
				}
			})
		}

		function otherActivity(cm, e) {
			for (let s = 0; s < cm.lineCount(); s++) {
				this_ref.checkLineWidgets(s, cm);
			}
		}

		let showHints = (editor, in_list, input) => {
			if (!this.file_loaded) return;
			let hint_types = {};
			let list = [];
			let text_added = []; // hints that area already added
			
			for (var o in in_list) {
				let hint_opts = in_list[o];
				let add = false;
				let text = hint_opts.fn || hint_opts.prop;

				if (input != '.' && !text.startsWith(input) && text != input) 
					continue;

				if (hint_opts.fn) {
					hint_types[text] = 'function1';
					add = true;
				}
				if (hint_opts.prop) {
					hint_types[text] = 'property';
					add = true;
				}
				if (add && !text_added.includes(text)) {
					text_added.push(text);
					list.push({
						text:text,
						hint_opts:hint_opts,
						render:function(el, editor, data) { el.innerHTML = this_ref.getCompleteHTML(hint_opts); }
					});
				}
			}
			blanke.cooldownFn("editor_show_hint", 250, function(){
				editor.showHint({
					closeOnUnfocus: false,
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

							this_ref.setFnHelper(this_ref.getCompleteHTML(completion.hint_opts));
						});

						return completions
					},
					completeSingle: false
				});
			});
		}

		let before_dot = '';
		new_editor.on("inputRead", function(cm, e){
			let editor = cm;
			let cursor = editor.getCursor();

/*
			if (this_ref.last_word == word) return;
			this_ref.last_word = word;
			*/

			checkGutterEvents(editor);
			this_ref.parseFunctions();
			this_ref.addAsterisk();
			
			blanke.cooldownFn('checkLineWidgets',500,()=>{
				otherActivity(cm,e)

				this_ref.refreshFnHelperTimer();

				let hint_list = [];
				// dot activation
				let word_pos = editor.findWordAt(cursor);
				let word = editor.getRange(word_pos.anchor, word_pos.head);
				let before_word_pos = editor.findWordAt({line: word_pos.anchor.line, ch: word_pos.anchor.ch-1});
				let before_word = editor.getRange(before_word_pos.anchor, before_word_pos.head);//before_word_pos, {line:before_word_pos.line, ch:before_word_pos.ch+1});
				let before_dot_pos = editor.findWordAt({line: before_word_pos.anchor.line, ch: before_word_pos.anchor.ch-1})
				if (before_word == '.') {
					before_dot = editor.getRange(before_dot_pos.anchor, before_dot_pos.head);
				} else {
					before_dot = '';
				}

				// word that triggered the dot
				let keyword = word;
				let keyword_pos = word_pos;
				if (word == '.') {
					keyword = before_word;
					keyword_pos = before_word_pos;
				}
				else if (before_dot != '') {
					keyword = before_dot;
					keyword_pos = before_dot_pos;
				}
				keyword = keyword.trim();

				let token = editor.getTokenAt(keyword_pos.head);//{line: word_pos.anchor.line, ch: word_pos.anchor.ch-1});
				let tokens = (token.type || '').split(' ');
				let is_key_or_var = tokens.includes('variable-2') || tokens.includes('variable') || tokens.includes('keyword');
				if (keyword != '') {
					// this -> replace with real instance type
					if (is_key_or_var && this_lines[this_ref.file]) {
						// look at previous lines until a 'this regex' is hit
						let loop = keyword_pos.head.line - 1;
						let this_lines_keys = Object.keys(this_lines[this_ref.file]);
						do {
							let line = (editor.getLine(loop) || '').trim();
							for (let l of this_lines_keys) {
								if (line.includes(l) && 
									(keyword == 'this')) { // || this_lines[this_ref.file][l].includes(keyword))) { // TODO: DOESNT WORK ATM
									tokens.push(this_lines[this_ref.file][l][0]);
								}
							}
							loop--;
						} while (loop >= 0);
					}
					for (let tok of tokens) {
						hint_list = hint_list.concat(hints[tok] || []);
					}
				}
				// 'global scope'
				if (word != '.' && is_key_or_var) {
					if (var_list[this_ref.file]) {
						// variable
						if (var_list[this_ref.file].var)
							var_list[this_ref.file].var.forEach(v => {
								if (v.startsWith(word))
									hint_list.push({ prop: v });
							})
						// function
						if (var_list[this_ref.file].fn)
							var_list[this_ref.file].fn.forEach(v => {
								if (v.startsWith(word))
									hint_list.push({ fn: v });
							})
					}
					// globals
					hint_list = hint_list.concat(hints.global);
				}
				if (hint_list.length > 0)
					showHints(editor, hint_list, word);
			});
		});

				
		new_editor.on('cursorActivity',function(cm){
			checkGutterEvents(cm);
		})
		new_editor.on('click', function(cm, obj){

			this_ref.focus();
		});
		new_editor.on('focus', function(cm){
			// TODO: this_ref.game.resume(); // NOTE: has a couple edge cases!
		});
		new_editor.on('blur', function(cm){
			// TODO: this_ref.game.pause(); // NOTE: has a couple edge cases!
		});

		if (this.codemirror == undefined) this.codemirror = new_editor;
		this.editors.push(new_editor);
		this.setFontSize(app.settings.code.font_size);

		return new_editor;
	}

	static parseLineSprite (text, cb) {
		let match;
		for (let re of re_image) {
			if (!match) match = re.exec(text);
		}
		if (!match) return;
		// found image path
		app.getAssetPath("image",match[1],(err, path)=>{	
			if (err) {	// no asset found
				cb(err, null);
				return;
			}
			// sprite info
			let info = { path:path, cropped: false, frame_size:[0,0], offset:[0,0], frames: 1};

			// use the first frame
			let re_frame_size = /frame_size\s*:\s*\[\s*(\d+)\s*,\s*(\d+)\s*\]/;
			let re_offset = /offset\s*:\s*\[\s*(\d+)\s*,\s*(\d+)\s*\]/;
			let re_frame = /frames\s*:\s*(\d+)/;
			let re_spacing = /spacing\s*:\s*\[\s*(\d+)\s*,\s*(\d+)\s*\]/;
			let re_comment = /\/(?:\/|\*).*/;

			let match;
			if (match = re_frame_size.exec(text.replace(re_comment,''))) {
				info.cropped = true;
				info.frame_size = [parseInt(match[1]),parseInt(match[2])];
			} else {
				// get image size
				let img = new Image();
				img.onload = () => {
					info.frame_size = [img.width, img.height];
					cb(null, info);
				}
				img.src = 'file://'+path;
			}
			if (match = re_offset.exec(text.replace(re_comment,''))) 
				info.offset = [parseInt(match[1]),parseInt(match[2])];
			
			if (match = re_frame.exec(text.replace(re_comment,''))) 
				info.frames = parseInt(match[1]);
			
			if (match = re_spacing.exec(text.replace(re_comment,''))) {
				info.offset[0] += parseInt(match[1]);
				info.offset[1] += parseInt(match[1]);
			}
			if (info.cropped) cb(null, info);
		});
	}

	checkLineWidgets (line, editor) {
		let l_info = editor.lineInfo(line);
		
		Code.parseLineSprite(l_info.text, (err, info) => {
			if (err) {
				// remove previous image
				if (l_info.widgets) {
					for (let w = 1; w < l_info.widgets.length; w++)
						l_info.widgets[w].clear();
				}
			}
			// create/set image widget
			else  {
				let el_image;
				if (l_info.widgets) {
					// clear extra widgets
					for (let w = 1; w < l_info.widgets.length; w++)
						l_info.widgets[w].clear();
					el_image = l_info.widgets[0].node;
				} else {
					el_image = app.createElement("div","code-image");
					editor.addLineWidget(line, el_image, {noHScroll:true});
					el_image.style.left = Math.floor(randomRange(50,80))+'%';
					el_image.style.backgroundPosition = '-'+info.offset[0]+'px -'+info.offset[1]+'px';
				
				}
				let img = new Image();
				img.onload = () => {
					if (info.cropped) {
						el_image.style.width=info.frame_size[0]+'px';
						el_image.style.height=info.frame_size[1]+'px';
					} else {
						el_image.style.width=img.width+'px';
						el_image.style.height=img.height+'px';
					}
					el_image.style.backgroundSize=img.width+'px '+img.height+'px';
					el_image.style.backgroundPosition=info.offset[0]+'px '+info.offset[1]+'px';
					el_image.style.backgroundRepeat="no-repeat";
				}
				img.src="file://"+app.cleanPath(info.path);
						
				el_image.style.backgroundImage = "url('file://"+app.cleanPath(info.path)+"')";
			}
		});
	}

	// TODO: not updated since hinting rework
	parseFunctions() {
		let this_ref = this;
		blanke.cooldownFn("parseFunctions", 1000, function(){
			let text = this_ref.codemirror.getValue()
			blanke.clearElement(this_ref.el_class_methods);

			// get function list
			let class_list = {};
			let re_func = [/function\s+(\w+):(\w+)\(([\w,\s]*)\)/g, /(\w+)\.(\w+)\s*=\s*function\s*\(([\w,\s]*)\)/g];
			for (let re of re_func) {
				let match;
				while (match = re.exec(text)) {
					let fn_info = {
						class:match[1],
						name:match[2],
						args:(match[3] || '').split(',').map((s) => s.trim())
					}
					this_ref.function_list.push(fn_info)
					
					// add it to functions to class string
					if (!class_list[fn_info.class]) class_list[fn_info.class] = `<div class="class-name">${fn_info.class}</div>`;
					class_list[fn_info.class] += `
						<div class="method-container">
							<div class="name">${fn_info.name}(<div class="args">${fn_info.args.join(', ')}</div>)</div>
						</div>
					`
				}
			}
			// combine all class strings
			for (let c in class_list) {
				this_ref.el_class_methods.innerHTML += class_list[c];
			}
		})
	}

	onClose () {
		delete code_instances[this.file];
	}

	goToLine(line) {
		this.codemirror.scrollIntoView({line:(line || 0),ch:0});
	}

	getCompleteHTML(hint) {
		let item_type = '';
		let text, render = '', arg_info = '';
		let re_optional = /\s*opt\w*\.?\s*/;

		if (hint.fn) {
			if (hint.callback)
				item_type = 'cb';
			else
				item_type = 'fn';
		} else if (hint.prop) {
			item_type = 'var';
		}

		if (item_type == 'cb' || item_type == 'fn') {
			text = hint.fn;
			if (hint.vars) {
				for (var arg in hint.vars) {
					let new_description = hint.vars[arg].replace(re_optional, '');
					if (new_description != "" && new_description != "...") 
						arg_info += arg + " : " + new_description + "<br/>";
				}
			}

			function specialReplacements(value, index, array) {
				if (value == 'etc')
					return '<span class="grayed-out">...</span>';
				// is arg optional?
				if (re_optional.test(hint.vars[value])) 
					return '<span class="optional">['+value+']</span>';
				// is arg a variable amount of args
				if (hint.vars[value] == '...')
					return '<span class="grayed-out">...</span>'+value;
				return value;
			}
			// named args or listed args
			let paren = ["(",")"];
			render = hint.fn + paren[0] + Object.keys(hint.vars || {}).map(specialReplacements) + paren[1] +
						"<p class='prop-info'>"+(hint.info || '')+"</p>"+
						"<p class='arg-info'>"+arg_info+"</p>"+
						"<p class='item-type'>"+item_type+"</p>";
		}
		else if (item_type == 'var') {
			text = hint.prop;
			render = hint.prop + "<p class='prop-info'>"+(hint.info || '')+"</p>"+
					"<p class='item-type'>"+item_type+"</p>";
		}

		return render;
	}

	setFnHelper (html) {
		if (this.no_fn_helper) return;
		this.el_fn_helper.classList.remove("hidden");
		this.el_fn_helper.innerHTML = html;
		this.refreshFnHelperTimer();
	}

	disableFnHelper () {
		this.no_fn_helper = true;
		this.clearFnHelper();
	}

	enableFnHelper () {
		this.no_fn_helper = false;
	}

	clearFnHelper () {
		this.el_fn_helper.innerHTML = '';
		this.el_fn_helper.classList.add("hidden");
	}

	// when timer runs out, hide fn_helper
	refreshFnHelperTimer () {
		if (this.no_fn_helper) return;
		let this_ref = this;
		clearTimeout(this.fn_helper_timer);
		this.fn_helper_timer = setTimeout(function(){
			this_ref.clearFnHelper();
		},15000);
	}

	addAsterisk () {
		if (this.file_loaded)
			this.setSubtitle("*");
	}

	removeAsterisk() {
		this.setSubtitle();
	}

	fontSizeUp () {
		app.settings.code.font_size += 1;
		this.setFontSize(app.settings.code.font_size);
	}

	fontSizeDown () {
		app.settings.code.font_size -= 1;
		this.setFontSize(app.settings.code.font_size);
	}

	setFontSize (num) {
		for (let editor of this.editors) {
			editor.display.wrapper.style['line-height'] = (num-2).toString()+"px";
			editor.display.wrapper.style.fontSize = num.toString()+"px";
			editor.refresh();
		}

		app.settings.code.font_size = num;
		app.saveAppData();
	}

	splitView () {
		if (this.edit_box2) return;

		this.edit_box.classList.add("split");
		this.edit_box2 = app.createElement("div", ["code","split"]);
		this.appendChild(this.edit_box2);

		let new_editor = this.setupEditor(this.edit_box2);
		new_editor.swapDoc(this.codemirror.getDoc().linkedDoc({sharedHist:true}));
		this.codemirror.refresh();
	}

	unsplitView () {
		if (!this.edit_box2) return;

		blanke.destroyElement(this.edit_box2);
		this.edit_box2 = null;
		this.edit_box.classList.remove("split");
		this.codemirror.refresh();
	}

	onMenuClick (e) {
		var this_ref = this;

		let split = {label:'split', click:function(){this_ref.splitView()}};
		if (this.edit_box2)
			split = {label:'unsplit', click:function(){this_ref.unsplitView()}};

		app.contextMenu(e.x, e.y, [
			split,
			{
				label:'show console',
				type:'checkbox',
				checked:this_ref.console.isVisible(),
				click:function(){this_ref.console.toggleVisibility()}
			},
			{
				label:'console auto-scroll',
				type:'checkbox',
				checked:this_ref.console.auto_scrolling,
				click:function(){this_ref.console.auto_scrolling = !this_ref.console.auto_scrolling}
			},
			{label:'rename', click:function(){this_ref.renameModal()}},
			{label:'delete', click:function(){this_ref.deleteModal()}}
		]);
	}

	edit (file_path) {
		this.file_loaded = false;
		var this_ref = this;

		this.file = file_path;
		code_instances[this.file] = this;

		var text = nwFS.readFileSync(file_path, 'utf-8');

		this.codemirror.setValue(text);
		this.codemirror.clearHistory();

		this.setTitle(nwPATH.basename(file_path));
		this.removeAsterisk();
		getKeywords(this.file, this.codemirror.getValue());
		this.parseFunctions();

		this.setOnClick(function(){
			Code.openScript(this_ref.file);
		});

		this.codemirror.refresh();
		this.file_loaded = true;
		return this;
	}

	refreshGame () {
		if (!this.deleted) {
			this.game.breakpoints = Object.keys(this.breakpoints).map(parseInt);
			this.game.refreshSource(this.file);
		}
	}

	save () {
		blanke.cooldownFn("codeSave", 200, ()=>{
			let data = this.codemirror.getValue();
			nwFS.writeFileSync(this.file, data);
			getKeywords(this.file, data);
			this.parseFunctions();
			Code.updateSpriteList(this.file, data);
			this.removeAsterisk();
			this.refreshGame();
		});
	}

	delete (path) {
		this.deleted = true;
		nwFS.remove(path);

		if (this.file == path) {
			this.close(true);
		}
	}

	deleteModal () {
		var name = this.file;
        var this_ref = this;
        blanke.showModal(
            "delete \'"+name+"\'?",
        {
            "yes": function() { this_ref.delete(name); },
            "no": function() {}
        });
	}

	rename (old_path, new_path) {
		var this_ref = this;
		app.renameSafely(old_path, new_path, (success) => {
			if (success) {
				this.file = new_path;
				this.setTitle(nwPATH.basename(this.file));
				if (this.game) this.game.setSourceFile(this.file);

			} else
				blanke.toast("could not rename \'"+nwPATH.basename(old_path)+"\'");
		})
	}

	renameModal () {
		var filename = this.file;
        var this_ref = this;
        blanke.showModal(
            "<label>new name: </label>"+
            "<input class='ui-input' id='new-file-name' style='width:100px;' value='"+nwPATH.basename(filename, nwPATH.extname(filename))+"'/>",
        {
            "yes": function() { 
                let new_path = nwPATH.join(nwPATH.dirname(filename), app.getElement('#new-file-name').value+".js");
                this_ref.rename(filename, new_path);
            },
            "no": function() {}
        });
	}

	static refreshCodeList(path) {
		app.removeSearchGroup("Scripts");
		Code.scripts = {other:[]};
		Code.sprites = {} // { EntitClassname: { image, crop: {x,y,w,h} } }
		for (let assoc of CODE_ASSOCIATIONS) {
			Code.scripts[assoc[1]] = [];
		}
		addScripts(path || app.getAssetPath('scripts'));
	}

	static openScript(file_path, line) {
		let editor = code_instances[file_path];
		if (!FibWindow.focus(nwPATH.basename(file_path))) {
			editor = new Code(app)
			editor.edit(file_path);
		}
		if (line != null) 
			editor.goToLine(line);
		blanke.cooldownFn("openScript-gamepreview", 200, function(){
			editor.refreshGame();
		});
	}

	static updateSpriteList(path, data) {
		blanke.cooldownFn('updateSpriteList.'+path, 500, ()=>{
			if (!data) data = nwFS.readFileSync(path, 'utf-8');
			if (!Code.sprites) Code.sprites = {};

			let lines = data.split("\n");
			let entity_class, token;
			let pivots = {};
			for (let line of lines) {
				// get token if passing one
				for (let txt in this_lines[path]) {
					if (line.includes(txt)) 
						token = this_lines[path][txt][0];
				}
				// convert token to class name
				if (token == 'blanke-entity-instance') {
					let match;
					for (let re of [].concat(re_class_extends.entity)) {
						match = re.exec(line);
						if (match) entity_class = match[1]
					}
				}
				let calcPivot = (e_class) => {
					let info = Code.sprites[e_class];
					let pivot = pivots[e_class];
					let x = 0, y = 0;
					if (info && pivot) {
						if (pivot.type == 1) { // sprite_align
							let align = pivot.match[1];
							if (align.includes('center')) {
								x = info.frame_size[0]/2;
								y = info.frame_size[1]/2;
							}
							if (align.includes('left'))
								x = 0;
							if (align.includes('right'))
								x = info.frame_size[0];
							if (align.includes('top'))
								y = 0;
							if (align.includes('bottom'))
								y = info.frame_size[1];
						} else if (info.type == 2) { // sprite_pivot.set(x,y)
							x = pivot.match[1];
							y = pivot.match[2];
						} else if (info.type == 3) { // sprite_pivot.x = ?
							if (pivot.match[1] == 'x') x = pivot.match[2];
							if (pivot.match[1] == 'y') y = pivot.match[2];
						}
						delete pivots[entity_class];
					}
					if (info)
						info.pivot = [x,y];
				}
				Code.parseLineSprite(line, (err, info) => {
					if (!err) {
						Code.sprites[entity_class] = info;
						calcPivot(entity_class);
					}
				})
				// optional: sprite alignment
				let match1 = re_sprite_align.exec(line);
				let match2 = re_sprite_pivot.exec(line);
				let match3 = re_sprite_pivot_single.exec(line);
				if (!pivots[entity_class])
					pivots[entity_class] = [];
				if (match1 || match2 || match3) {
					pivots[entity_class] = {
						type: (match1 ? 1 : match2 ? 2 : 3),
						match: (match1 || match2 || match3)
					};
					calcPivot(entity_class);
				}
			}
		});
	}
}

Code.scripts = {};
document.addEventListener('fileChange', function(e){
	if (e.detail.file.includes("scripts")) {
		Code.refreshCodeList();
	}
});

Code.classes = {};
function addScripts(folder_path) {
	Code.classes = {
		'scene':[],
		'entity':[]
	};
	
	nwFS.readdir(folder_path, function(err, files) {
		if (err) return;
		script_list = files.map(f => app.cleanPath(nwPATH.join(folder_path,f)));
		for (let file of files) {
			var full_path = app.cleanPath(nwPATH.join(folder_path, file));
			
			// is a script?
			if (file.endsWith('.js')) {
				// get what kind of script it is
				let data = nwFS.readFileSync(full_path, 'utf-8');
				getKeywords(full_path, data);
				// get what kind of script it is
				let tags = ['script'];
				let cat, match;
				for (let assoc of CODE_ASSOCIATIONS) {
					match = assoc[0].exec(data);
					if (match) {
						cat = assoc[1];
						tags.push(assoc[1]);
						if (!Code.scripts[assoc[1]].includes(full_path)) {
							Code.scripts[assoc[1]].push(full_path);
						}
						// store the class name
						if (Object.keys(Code.classes).includes(cat)) {
							Code.classes[cat].push(match[1]);
						}
					}
				}
				if (!cat) 
					Code.scripts.other.push(full_path);
				
				// add file to search pool
				app.addSearchKey({
					key: file,
					onSelect: function(file_path){
						Code.openScript(file_path);
					},
					tags: tags,
					category: cat,
					args: [full_path],
					group: 'Scripts'
				});

				// if script has Entity class find if it has sprite
				Code.updateSpriteList(full_path, data)
			}
		};

		// first scene setting
		let first_scene = app.project_settings.first_scene;
		let scenes = Code.classes['scene'];
		if (!(first_scene && scenes.includes(first_scene)) && scenes.length > 0) {
			app.project_settings.first_scene = scenes[0];
			app.saveSettings();
		}
	});
}

document.addEventListener("closeProject", function(e){	
	app.removeSearchGroup("Code");
});

document.addEventListener("autocompleteChanged",(e)=>{
	reloadCompletions();
});

document.addEventListener("openProject", function(e){
	reloadCompletions();
	Code.refreshCodeList();

	function key_addScript(content,name) {
		var script_dir = nwPATH.join(app.project_path,'scripts');
		nwFS.stat(script_dir, function(err, stat) {
			if (err) nwFS.mkdirSync(script_dir);

			nwFS.readdir(script_dir, function(err, files){
				let file_name = ifndef(name,'script'+files.length)+'.js';
				content = content.replaceAll("<NAME>", name);

				// the file already exists. open it
				if (files.includes(file_name)) {
					blanke.toast("Script already exists!");
					Code.openScript(nwPATH.join(script_dir, file_name))
				} else {
					// no such script, go ahead and make one
					nwFS.writeFile(nwPATH.join(script_dir, file_name), content, function(err){
						if (!err) {
							// edit the new script
							Code.openScript(nwPATH.join(script_dir, file_name));
						}
					});
				}

			});
		});
	}

	function key_newScriptModal(s_type, content) {
		blanke.showModal(
			"<label style='line-height:35px'>Name your new "+s_type+":</label></br>"+
			"<input class='ui-input' id='new-script-name' style='width:100px;'/>",
		{
			"yes": function() {
				let name = app.getElement("#new-script-name").value.trim();
				if (name != '')
					key_addScript(content, name);
				else
					blanke.toast("bad name for new "+s_type);
			},
			"no": function() {}
		});
	}

	app.addSearchKey({
		key: 'Add a script',
		onSelect: function() {
			key_addScript("");
		},
		tags: ['new'],
		group: 'Code'
	});
	app.addSearchKey({
		key: 'Add a scene',
		onSelect: function() {
			key_newScriptModal("scene",
`Scene("<NAME>",{
    onStart: function(scene) {

    },
    onUpdate: function(scene, dt) {
        
    },
    onEnd: function(scene) {

    }
});
`);
		},
		tags: ['new'],
		category: 'scene',
		group: 'Code'
	});
	app.addSearchKey({
		key: 'Add an entity',
		onSelect: function() {
			key_newScriptModal("entity",
`class <NAME> extends Entity {
    init () {

    }
    update (dt) {

    }
}
`);
		},
		tags: ['new'],
		category: 'entity',
		group: 'Code'
	});
});
