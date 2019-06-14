/* list of changes
	re_class_list: removed ^ at beginning
	changed order in defineMode: instance > class_list
*/
var code_instances = {};

var CODE_ASSOCIATIONS = [
	[
		/\bScene\s*\(\s*[\'\"](.+)[\'\"]/g,
		"scene"
	],[
		/(\w+)\s+extends\s+Entity\s*/g,
		"entity"
	],
];

var object_list = {}
var object_src = {};
var object_instances = {};
var user_words = [];
var keywords = [];

var autocomplete, callbacks, hints;
var re_class, re_class_list, re_class_and_instance, re_instance, re_user_words;
var re_image = /Image\(["']([\w\s\/.-]+)["']\)/;
var re_animation = /self:addSprite[\s\w{(="',]+image[\s=]+['"]([\w\s\/.-]+)/;
var re_sprite = /Sprite[\s\w{(="',]+image[\s=]+['"]([\w\s\/.-]+)/;

function isReservedWord(word) {
	return keywords.includes(word) || autocomplete.class_list.includes(word);
}

function reloadCompletions() {
	autocomplete = app.require(app.settings.autocomplete_path);

	re_class = autocomplete.class_regex;
	re_class_list = null;
	if (autocomplete.class_list)
		re_class_list = '('+autocomplete.class_list.join('|')+')';
	hints = autocomplete.completions;
	re_instance = autocomplete.instance_regex;
	re_user_words = autocomplete.user_words;
	keywords = autocomplete.keywords;

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

	// find words that the user made using 'local' or whatever
	user_words[filename] = [];
	// variables
	for (let r in re_user_words.var) {
		let re = re_user_words.var[r];
		let match;
		while (match = re.exec(content)) {
			if (!isReservedWord(match[1])) {
				user_words[filename].push({
					prop:match[1],
					global:true
				});
			}
		}
	}
	// functions
	for (let r in re_user_words.fn) {
		let re = re_user_words.fn[r];
		let match;
		while (match = re.exec(content)) {
			if (!isReservedWord(match[1])) {
				user_words[filename].push({
					fn:match[1],
					global:true
				});
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

	function checkInstance(cat, regex) {
		var ret_instance_match;

		if(!object_instances[filename])
			object_instances[filename] = {};
		if(!object_instances[filename][cat])
			object_instances[filename][cat] = [];
		do {
			ret_instance_match = regex.exec(content);
			if (!ret_instance_match) {
				// continue; // no longer usable after adding 'for (let obj_name of ret_matches)'
			}
			else if(!object_instances[filename][cat].includes(ret_instance_match[1])) {
				object_instances[filename][cat].push(ret_instance_match[1]);
			}

		} while (ret_instance_match)
	}

	for (let category in object_list) {
		for (let obj_name in object_list[category]) {
			// get instances made with those classes
			if (re_instance[category]) {
				if (Array.isArray(re_instance[category])) {
					for (let subre of re_instance[category]) {
						checkInstance(category, new RegExp(subre.source.replace('<class_name>', obj_name), subre.flags))
					}
				} else {
					checkInstance(category, new RegExp(re_instance[category].source.replace('<class_name>', obj_name), re_instance[category].flags));
				}
			}
		}
	}
}

class Code extends Editor {
	constructor () {
		super();
		this.setupFibWindow();
		var this_ref = this;
		this.file = '';
		this.script_folder = "/scripts";

		if (!app.settings.code) app.settings.code = {};
		ifndef_obj(app.settings.code, {
			font_size:16
		});

		this.editors = [];
		this.function_list = [];

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
		this.game = new GamePreview();
		this.console = new Console();
		this.console.appendTo(this.getContent());
		this.getContainer().bg_first_only = true;
		this.appendBackground(this.game.container);

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

		      	// class list (Draw, Asset, etc)
				if (re_class_list) {
					let match = stream.match(new RegExp(re_class_list));
					if (match) {
						return baseCur+"blanke-class blanke-"+match[1].toLowerCase();
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
		  return CodeMirror.overlayMode(CodeMirror.getMode(config, parserConfig.backdrop || "javascript"), blankeOverlay);
		});

		this.setupEditor(this.edit_box);

		this.gutterEvents = {
			':addSpr':{
				tooltip:'make a spritesheet animation',
				fn:function(line_text, cm, cur){
					// get currently used image name
					let image_name = '';
					if (image_name = line_text.match(/self:addSprite{.*image\s*=\s*('|")([\\-\s\w]*)\1/)) 
						image_name = image_name[2]

					let spr_prvw = new SpritesheetPreview(image_name);
					spr_prvw.onCopyCode = function(vals){
						let rows = Math.floor(vals.frames/vals.columns);

						let args = {
							name:'\"'+(vals.name == '' || !vals.name ? 'my_animation' : vals.name)+'\"',
							image:'\"'+app.cleanPath(vals.image.replace(/.*[\/\\](.*)\.\w+/g,"$1"))+'\"',
							frames:"{"+vals['selected frames'].join(',')+"}",
							frame_size:"{"+vals['frame size'].join(',')+"}",
							speed:vals.speed,
							offset:"{"+[vals.offset[0],vals.offset[1]].join(',')+"}",
							border:vals.border
						}
						let arg_str = "";
						for (let key in args) {
							arg_str += (key+"="+args[key]+", ");
						}
						arg_str = arg_str.slice(0,-2);
						line_text = line_text.replace(/(\s*)(\w+):addSprite.*/g,"$1$2:addSprite{"+arg_str+"}");
						
						this_ref.codemirror.replaceRange(line_text,
							{line:cur.line,ch:0}, {line:cur.line,ch:10000000});
					}
				}
			},
			'[^add:]Sprite':{
				tooltip:'make a spritesheet animation',
				fn:function(line_text, cm, cur){
					// get currently used image name
					let image_name = '';
					if (image_name = line_text.match(/Sprite{.*image\s*=\s*('|")([\\-\s\w]*)\1/)) 
						image_name = image_name[2]

					let spr_prvw = new SpritesheetPreview(image_name);
					spr_prvw.onCopyCode = function(vals){
						let rows = Math.floor(vals.frames/vals.columns);

						let args = {
							image:'\"'+app.cleanPath(vals.image.replace(/.*[\/\\](.*)\.\w+/g,"$1"))+'\"',
							frames:"{"+vals['selected frames'].join(',')+"}",
							frame_size:"{"+vals['frame size'].join(',')+"}",
							speed:vals.speed,
							offset:"{"+[vals.offset[0],vals.offset[1]].join(',')+"}"
							// TODO: border (padding)
						}
						let arg_str = "";
						for (let key in args) {
							arg_str += (key+"="+args[key]+", ");
						}
						arg_str = arg_str.slice(0,-2);
						line_text = line_text.replace(/Sprite.*/g,"Sprite{"+arg_str+"}");
						
						this_ref.codemirror.replaceRange(line_text,
							{line:cur.line,ch:0}, {line:cur.line,ch:10000000});
					}
				}
			}
		}

		this.autocompleting = false;
		this.last_word = '';

		this.addCallback('onFocus', function() {
			this_ref.game.refreshSource(this_ref.file);
		});

		this.addCallback('onResize', function(w, h) {
			// move split view around if there is one
			let content_area = this_ref.getContent();
			content_area.classList.remove("horizontal","vertical");
			if (w > h) content_area.classList.add("horizontal");
			if (h > w) content_area.classList.add("vertical");

			this_ref.codemirror.refresh();
		});

		this.game.onError = (msg, file, lineNo, columnNo) => {
			let file_link = `<a href='#' onclick="Code.openScript('${file}')">${nwPATH.basename(file)}</a>`;
			this.console.err(`${file_link} (&darr;${lineNo}&rarr;${columnNo}): ${msg}`);
		}
		this.game.onLog = (msgs) => {
			this.console.log(msgs.join(' '));
		}
		this.game.onRefresh = () => {
			this.console.clear();
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
            gutters:["CodeMirror-linenumbers","gutter-event"],
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
            	"Ctrl-=": function(cm) { this_ref.fontSizeUp(); },
            	"Ctrl--": function(cm) { this_ref.fontSizeDown(); },
            	"Cmd-=": function(cm) { this_ref.fontSizeUp(); },
            	"Cmd--": function(cm) { this_ref.fontSizeDown(); },
            	"Shift-Tab": "indentLess",
            	"Ctrl-F": "findPersistent",
            	"Ctrl-Space": "autocomplete"
            }
		});
		
		// set up events
		//this.codemirror.setSize("100%", "100%");
		function checkGutterEvents(cm, obj) {
			let cur = cm.getCursor();
			let line_text = cm.getLine(cur.line);
			cm.clearGutter('gutter-event');
			
			for (let txt in this_ref.gutterEvents) {
				if (line_text.match(new RegExp(txt))) {
					let el_gutter = blanke.createElement('div','gutter-evt');
					el_gutter.innerHTML="<i class='mdi mdi-flash'></i>";
					if (this_ref.gutterEvents[txt].tooltip)
						el_gutter.title = this_ref.gutterEvents[txt].tooltip;
					el_gutter.addEventListener('click',function(){
						this_ref.gutterEvents[txt].fn(line_text, cm, cur);
					});
					cm.setGutterMarker(cur.line, 'gutter-event', el_gutter);
				}
			}
		}

		function otherActivity(cm, e) {
			for (let s = 0; s < cm.lineCount(); s++) {
				this_ref.checkLineWidgets(s, cm);
			}
		}

		new_editor.on("change", function(cm, e){
			let editor = cm;
			let cursor = editor.getCursor();

			let word_pos = editor.findWordAt(cursor);
			let word = editor.getRange(word_pos.anchor, word_pos.head);
			let before_word_pos = {line: word_pos.anchor.line, ch: word_pos.anchor.ch-1};
			let before_word = editor.getRange(before_word_pos, {line:before_word_pos.line, ch:before_word_pos.ch+1});
			let word_slice = word.slice(-1);

			checkGutterEvents(editor);
			blanke.cooldownFn('checkLineWidgets',250,()=>{otherActivity(cm,e)})

			this_ref.parseFunctions();
			this_ref.addAsterisk();
			this_ref.refreshFnHelperTimer();

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
				if (hints.global) {
					for (let h = 0; h < hints.global.length; h++) {
						hints.global[h].global = true;
						hint_list.push(hints.global[h]);
					}
				}

				// add user-made words
				for (let u in user_words[this_ref.file]) {
					hint_list.push(user_words[this_ref.file][u]);
				}

				// iterate through hint suggestions
				for (var o in hint_list) {
					let hint_opts = hint_list[o];
					let add = false;
					let text = hint_opts.fn || hint_opts.prop;

					if (hint_opts.fn && 
						(
							(hint_opts.global && globalActivator()) || 
							(activator == ':' && !hint_opts.global && (token_type.includes('instance') || hint_opts.callback)) || 
							(activator == '.' && !hint_opts.global && !hint_opts.callback && !token_type.includes('instance'))
						) && containsTyped(hint_opts.fn)
					) {
						hint_types[text] = 'function1';
						if (hint_opts.named_args) {
							hint_types[text] = 'function2';
						}
						add = true;
					}
					if (hint_opts.prop && 
						((activator == '.' && !hint_opts.global) || (hint_opts.global && globalActivator())) && 
						!hint_opts.callback && containsTyped(hint_opts.prop)) {
						hint_types[text] = 'property';
						add = true;
					}
					if (add) {
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
								else if (hint_types[completion.text] == 'function2')
									editor.replaceRange(completion.text+'{', comp_word.anchor, comp_word.head);

								this_ref.setFnHelper(this_ref.getCompleteHTML(completion.hint_opts));
							});

							return completions
						},
						completeSingle: false
					});
				});
			}
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

	checkLineWidgets (line, editor) {
		let this_ref = this;
		let info = editor.lineInfo(line);
		
		let match;
		
		if ((match = re_image.exec(info.text)) || (match = re_animation.exec(info.text)) || (match = re_sprite.exec(info.text))) {
			app.getAssetPath("image",match[1],(err, path)=>{	
				// no asset found
				if (err) {
					// remove previous image
					if (info.widgets) {
						for (let w = 1; w < info.widgets.length; w++)
							info.widgets[w].clear();
						//delete this_ref.widgets[line];
					}
				}
				
				// create/set image widget
				else  {
					let el_image;
					if (info.widgets) {
						// clear extra widgets
						for (let w = 1; w < info.widgets.length; w++)
							info.widgets[w].clear();
						el_image = info.widgets[0].node;
					} else {
						el_image = app.createElement("div","code-image");
						editor.addLineWidget(line, el_image, {noHScroll:true});
						el_image.style.left = Math.floor(randomRange(50,80))+'%';
					}

					// use the first frame
					let match, sprite = false;
					let frame_size = [0,0];
					let re_frame_size = /frame_size[\s=]+{\s*(\d+)\s*,\s*(\d+)\s*}/;
					if (match = re_frame_size.exec(info.text)) {
						sprite = true;
						frame_size = [parseInt(match[1]),parseInt(match[2])];
						el_image.style.width = frame_size[0]+'px';
						el_image.style.height = frame_size[1]+'px';
					}
					let offset=[0,0];
					let re_offset = /offset[\s=]+{\s*(\d+)\s*,\s*(\d+)\s*}/;
					if (match = re_offset.exec(info.text)) {
						offset = [parseInt(match[1]),parseInt(match[2])];
					}
					let re_frame = /frames={["']?(\d)+(?:-\d+["'])?,["']?(\d)+-?/;
					if (match = re_frame.exec(info.text.replace(/ /g,''))) {
						let frame = [parseInt(match[1]),parseInt(match[2])];
						offset[0] += frame_size[0] * (frame[0]-1);
						offset[1] += frame_size[1] * (frame[1]-1);
					}
					let re_border = /border=(\d+)/;
					if (match = re_border.exec(info.text.replace(/ /g,''))) {
						offset[0] += parseInt(match[1]);
						offset[1] += parseInt(match[1]);
					}
					el_image.style.backgroundPosition = '-'+offset[0]+'px -'+offset[1]+'px';
					
					let re_fr
					// uncropped image
					if (!sprite) {
						let img = new Image();
						img.onload = () => {
							el_image.style.width=img.width+'px';
							el_image.style.height=img.height+'px';
							el_image.style.backgroundSize="cover";
							el_image.style.backgroundRepeat="no-repeat";
							el_image.style.backgroundPosition="center";
						}
						img.src="file://"+app.cleanPath(path);
					}
							
					el_image.style.backgroundImage = "url('file://"+app.cleanPath(path)+"')";
				}
			});
		} 
	}

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
					if (new_description != "") 
						arg_info += arg + " : " + new_description + "<br/>";
				}
			}

			function specialReplacements(value, index, array) {
				if (value == 'etc')
					return '<span class="grayed-out">...</span>';
				// is arg optional?
				if (re_optional.test(hint.vars[value])) 
					return '<span class="optional">['+value+']</span>';
				return value;
			}
			// named args or listed args
			let paren = ["(",")"];
			if (hint.named_args) {
				paren = ["{","}"];
			}
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
		this.el_fn_helper.classList.remove("hidden");
		this.el_fn_helper.innerHTML = html;
		this.refreshFnHelperTimer();
	}

	clearFnHelper () {
		this.el_fn_helper.innerHTML = '';
		this.el_fn_helper.classList.add("hidden");
	}

	// when timer runs out, hide fn_helper
	refreshFnHelperTimer () {
		let this_ref = this;
		clearTimeout(this.fn_helper_timer);
		this.fn_helper_timer = setTimeout(function(){
			this_ref.clearFnHelper();
		},15000);
	}

	addAsterisk () {
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
			{label:'rename', click:function(){this_ref.renameModal()}},
			{label:'delete', click:function(){this_ref.deleteModal()}}
		]);
	}

	edit (file_path) {
		var this_ref = this;

		this.file = file_path;
		code_instances[this.file] = this;

		var text = nwFS.readFileSync(file_path, 'utf-8');

		this.codemirror.setValue(text);
		this.codemirror.clearHistory();

		this.setTitle(nwPATH.basename(file_path));
		this.removeAsterisk();
		refreshObjectList(this.file, this.codemirror.getValue());
		this.parseFunctions();

		this.setOnClick(function(){
			Code.openScript(this_ref.file);
		});

		this.codemirror.refresh();
		return this;
	}

	save () {
		let this_ref = this;
		blanke.cooldownFn("codeSave", 200, function(){
			nwFS.writeFileSync(this_ref.file, this_ref.codemirror.getValue());
			refreshObjectList(this_ref.file, this_ref.codemirror.getValue());
			this_ref.parseFunctions();
			this_ref.removeAsterisk();
			this_ref.game.refreshSource(this_ref.file);
		});
	}

	delete (path) {
		nwFS.unlink(path);

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
				this_ref.file = new_path;
				this_ref.setTitle(nwPATH.basename(this_ref.file));

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
		for (let assoc of CODE_ASSOCIATIONS) {
			Code.scripts[assoc[1]] = [];
		}
		addScripts(path || app.project_path);
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
			editor.game.refreshSource(editor.file);
		});
	}
}

Code.scripts = {};
document.addEventListener('fileChange', function(e){
	if (e.detail.file.includes("scripts")) {
		Code.refreshCodeList();
	}
});

function addScripts(folder_path) {
	Code.classes = {
		'scene':[],
		'entity':[]
	};
	_addScripts(folder_path);
}

function _addScripts(folder_path) {
	nwFS.readdir(folder_path, function(err, files) {
		if (err) return;
		for (let file of files) {
			var full_path = nwPATH.join(folder_path, file);
			let file_stat = nwFS.statSync(full_path);		
			// iterate through directory		
			if (file_stat.isDirectory() && file != "dist") 
				_addScripts(full_path);

			// is a script?
			else if (file.endsWith('.js')) {
				// get what kind of script it is
				let data = nwFS.readFileSync(full_path, 'utf-8');
				refreshObjectList(full_path, data);
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
						// first scene setting
						if (cat == 'scene' && !app.project_settings.first_scene) {
							app.project_settings.first_scene = match[1];
							app.saveSettings();
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
			}
		};
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
			key_newScriptModal("scene",`
Scene("<NAME>",{
    onStart: function() {

    },
    onUpdate: function() {
        
    },
    onEnd: function() {

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
			key_newScriptModal("entity",`
class <NAME> extends Entity {
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
