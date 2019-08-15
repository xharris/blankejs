let getHTML = (body, ide_mode) => {
let fonts = app.asset_list.reduce((arr, val) => {
			if (app.findAssetType(val) == 'font')
				arr.push(val);
			return arr;
		},[])
		.map(v => `
@font-face {
	font-family: '${nwPATH.parse(v).name}';
	src: url('${
		ide_mode ? 
		app.cleanPath(nwPATH.relative("src",nwPATH.join(app.project_path))) + '/' + app.shortenAsset(v):
		app.shortenAsset(v)
	}');
}
`)
return `
<!DOCTYPE html>
<html>
	<style>
		head, body {
			position: absolute;
			top: 0px;
			left: 0px;
			right: 0px;
			bottom: 0px;
			margin: 0px;
			overflow: hidden;
			background: #485358;
		}
		#game {
			width: 100%;
			height: 100%;
			background: #485358;
		}
		body > img {
			width: 100%;
			height: 100%;
		}
		${fonts.join('\n')}
	</style>
	<head>
		<script type="text/javascript">${app.engine_code}</script>
	</head>
	${body}
</html>
`};
/* goes in refreshSource
${inf_loop_detector}
		let test_code = infiniteLoopDetector.wrap(\`${code.replaceAll('\`','\\`')}\`);
		try {
			eval(test_code);
		} catch (e) {
			console.log("no")
			throw e;
		}
		*/
let inf_loop_detector = `
var infiniteLoopDetector = (function() {
  var map = {}

  // define an InfiniteLoopError class
  function InfiniteLoopError(msg, type) {
    Error.call(this ,msg)
    this.type = 'InfiniteLoopError'
  }
  
  function infiniteLoopDetector(id) {
    if (id in map) { 
      if (Date.now() - map[id] > 1000) {
        delete map[id]
        throw new Error('Loop runing too long!', 'InfiniteLoopError')
      }
    } else { 
		map[id] = Date.now()
    }
  }

  infiniteLoopDetector.wrap = function(codeStr) {
    if (typeof codeStr !== 'string') {
      throw new Error('Can only wrap code represented by string, not any other thing at the time! If you want to wrap a function, convert it to string first.')
    }
    // this is not a strong regex, but enough to use at the time
    return codeStr.replace(/for *\\(.*\\{|while *\\(.*\\{|do *\\{/g, function(loopHead) {
      var id = parseInt(Math.random() * Number.MAX_SAFE_INTEGER)
      return \`infiniteLoopDetector(\${id});\${loopHead}infiniteLoopDetector(\${id});\`
    })
  }

  infiniteLoopDetector.unwrap = function(codeStr) {
    return codeStr.replace(/infiniteLoopDetector\\([0-9]*?\\);/g, '')
  }
   return infiniteLoopDetector
}())
`;

let re_scene_name = /\bScene\s*\(\s*[\'\"](.+)[\'\"]/;
let re_new_line = /(\r\n|\r|\n)/g;
let re_error_line = /<anonymous>:(\d+):(\d+)\)/;

class GamePreview {
	constructor (parent, opt) {
		let this_ref = this;

		this.game = null;
		this.container = app.createElement("div","game-preview-container");
		this.iframe = app.createElement("iframe");
		this.id = "game-"+guid();
		this.iframe.id = this.id;
		this.parent = parent || document.createDocumentFragment();
		this.line_ranges = {};
		this.size = 0;
		this.breakpoints = [];

		this.options = ifndef_obj(opt, {
			ide_mode: true,
			scene: null,
			size: null,
			onLoad: null
		});
		
		// engine loaded
		this.refresh_file = null;
		this.errored = false;
		this.last_code = null;
		this.iframe.addEventListener('load', () => {
			let iframe = this.iframe;
			let doc = iframe.contentDocument;
			let canvas = doc.querySelectorAll("#game canvas");
			canvas.forEach(el => el.remove());
			
			if (this.errored) {
				return;
			}

			if (this.refresh_file) {
				this.refreshSource(this.refresh_file);
			}
			if (this.options.onLoad)
				this.options.onLoad(this);

			iframe.contentWindow.onerror = (msg, url, lineNo, columnNo, error) => {
				this.pause();
				this.errored = true;
				// get line and col
				let match = re_error_line.exec(error.stack);
				if (match) {
					lineNo = parseInt(match[1]);
					columnNo = parseInt(match[2]);
				}
				msg = msg.replace("Uncaught Error: ","");
				if (this.onError) {
					let file, range;
					for (let f in this.line_ranges) {
						range = this.line_ranges[f];
						if (lineNo > range.start && lineNo < range.end) {
							file = f;
							break;
						}
					}
					if (file)
						this.onError(msg, file, lineNo - range.start, columnNo);

				}
				console.error(msg, url, lineNo, columnNo, error)
				return true;
			}
			if (this.onLog) {
				let old_warn = iframe.contentWindow.console.warn;
				iframe.contentWindow.console = {
					warn: old_warn,
					log:  (...args) => {
						this.onLog(...args)
						//old_log(...args);
					},
					superlog: (...args) => {
						console.log(...args);
					}
				}
			}

			if (this.last_code) {
				let old_script = doc.querySelectorAll('script.source');
				if (old_script)
					old_script.forEach((el) => el.remove());
				let parent= doc.getElementsByTagName('body')[0];
				let script= doc.createElement('script');
				script.classList.add("source");
				script.innerHTML= this.last_code;
				parent.appendChild(script);
				this.last_code = null;
			}
			this.game = this.iframe.contentWindow.game_instance;
			if (this.game)
				this.game.Game.onPause = ()=>{
					this.game_checkpaused();
				}
			if (this.onRefresh) this.onRefresh();
		})
		this.refreshSource();
		this.parent.appendChild(this.iframe);

		this.paused = false;
		document.addEventListener('engineChange',(e)=>{
			if (!this.paused || this.errored)
				this.refreshEngine();	
		});
		document.addEventListener('assetsChange',(e)=>{
			if (!this.paused || this.errored)
				this.refreshEngine();
		});

		// game controls
		this.el_control_bar = app.createElement("div","control-bar");
		this.el_refresh = app.createIconButton("refresh","refresh");
		this.el_refresh.addEventListener('click',()=>{
			this.refreshSource();
		});
		this.el_control_bar.appendChild(this.el_refresh);
		this.el_control_bar = app.createElement("div","control-bar");
		this.el_pauseplay = app.createIconButton("pause","pause");
		this.el_pauseplay.addEventListener('click',()=>{
			this.game_paused() ? this.game_resume() : this.game_pause();
			this.game_checkpaused();
		});
		this.el_control_bar.appendChild(this.el_pauseplay);
		this.el_step = app.createIconButton("step","step once");
		this.el_step.addEventListener('click',()=>{
			this.game_step();
		});
		this.el_control_bar.appendChild(this.el_step);

		this.container.appendChild(this.iframe);
		this.container.appendChild(this.el_control_bar);
	}

	get width () {
		if (this.game) return this.game.Game.width;
	}

	get height () {
		if (this.game) return this.game.Game.height;
	}
	game_checkpaused () {
		if (this.game_paused())
			this.el_pauseplay.change('run','resume preview');
		else 
			this.el_pauseplay.change('pause','pause preview');
	}
	game_paused () { return this.game ? this.game.Game.paused : null; }
	game_pause () {
		if (this.game) this.game.Game.pause();
	}
	game_resume () {
		if (this.game) this.game.Game.resume();
	}
	game_step () {
		if (this.game) this.game.Game.step();
	}
	pause () {
		this.paused = true;
		if (this.game)
			this.game.Game.freeze();
	}
	resume () {
		this.paused = false;
		if (this.game && !this.errored)
			this.game.Game.unfreeze();
	}

	getAssets () {
		let str_assets = [];

	}

	getSource () {
		return getHTML(`
		<body>
			<div id="game"></div>
		</body>
		<script>
			let app = window.parent.app;
			window.addEventListener('dragover', function(e) {
				e.preventDefault();
				return false;
			});
			window.addEventListener('drop', function(e) {
				e.preventDefault();
				return false;
			});
			window.addEventListener('dragleave', function(e) {
				e.preventDefault();
				return false;
			});
			var game_instance = Blanke("#game",{
				config: ${JSON.stringify(app.project_settings)},
				fill_parent: false,
				width: ${this.options.size[0]},
				height: ${this.options.size[1]},
				${this.options.resizable ? 'resizable: true,' : '' }
				assets: [${this.getAssetStr()}],
				onLoad: function(){
					${this.refreshSource()}
				}
			});
		</script>`, this.options.ide_mode);
	}

	getAssetStr () {
		let ret = `
					["config.json"],
					${app.asset_list.reduce((arr, val) => {
						if (val.includes('assets'))
							arr.push(`["assets/${app.shortenAsset(val)}"]`)
						return arr;
					},[]).join(',\n\t\t\t\t\t')}
				`;
		return ret;
	}

	static getScriptOrder (curr_script) {
		let scripts = [];
		let curr_script_cat = 'other';
		let found = false;
		for (let cat of ['other','entity','scene']) {
			if (Array.isArray(Code.scripts[cat])) {
				// put current_script at end
				scripts = scripts.concat(Code.scripts[cat].filter(val => {
					if (val == curr_script) {
						found = true;
						curr_script_cat = cat;
					}
					return (!curr_script || val != curr_script) && !scripts.includes(val);
				}));
			}
		}
		if (found)
			scripts.push(curr_script);
		if (curr_script)
			return [ scripts, curr_script_cat ];
		return scripts;
	}

	getExtraEngineCode () {
		let view_size = ``;
		// TODO: take another look at this. game viewport is cutoff
		if (this.options.ide_mode && this.size > 0) {
				view_size = `
						view.port_width = window.innerWidth;
						view.port_height = window.innerHeight;
				`;
			if (this.size == 1) {
				view_size = `
						view.port_width = window.innerWidth / 2;
						view.port_height = window.innerHeight;
				`;
			}
			if (this.size == 2) {
				view_size = `
						view.port_width = window.innerWidth / 2;
						view.port_height = window.innerHeight / 2;
				`;
			}
			return `
			let TestScene = (funcs) => {
				Scene("_test", funcs);
			}
			let TestView = (follow_obj) => {
				let view = View();
				if (follow_obj)
					view.follow(follow_obj);
				${view_size}
				return view;
			}
			let _resizeTestView = (name) => {
				let view = View(name);
				if (!view.dont_resize) {
					${view_size}
				}
			}
			window.addEventListener('resize',()=>{
				let view_list = View.names();
				for (let name of view_list) {
					if (name.startsWith('_test')) {
						_resizeTestView(name);
					}
				}
			});
			`;
		}
		return `
		let TestScene = () => {};
		let TestView = () => {};
		`;
	}
	
	refreshSource (current_script) {
		if (this.errored) {	
			this.errored = false;
		}
		this.last_script = current_script;
		if (!this.game) 
			this.refresh_file = app.cleanPath(current_script);
		if (this.refresh_file) {
			current_script = this.refresh_file
			this.refresh_file = null;
		}
		if (this.game)
			this.game.Game.end();

		let post_load = '';
		// get all the scripts
		let scripts = [];
		let curr_script_cat = 'other';
		let contains_test_scene = false;

		if (current_script && nwFS.pathExistsSync(current_script)) {
			[ scripts, curr_script_cat ] = GamePreview.getScriptOrder(current_script);
			let file_data = nwFS.readFileSync(current_script,'utf-8');
			contains_test_scene = file_data.includes('TestScene({')
		} else 
			scripts = GamePreview.getScriptOrder()
		switch (curr_script_cat) {
			case 'entity':
				if (this.options.ide_mode && contains_test_scene)
					post_load += '\nScene.start("_test");\n';
				break;
			case 'scene':
				let match = re_scene_name.exec(nwFS.readFileSync(current_script,'utf-8'));
				if (match && match.length > 1) {
					if (contains_test_scene)
						post_load += '\nScene.start("_test");\n';
					else {
						post_load += `\nScene.start("${match[1]}");\n`;
					}
				}
				break;
			case 'other':
				if (contains_test_scene)
					post_load += '\nScene.start("_test");\n';
				else if (this.options.scene) {
					post_load += '\nScene.start("'+this.options.scene+'");\n';
				}
				break;
		}

		// wrapped in a function so local variables are destroyed on reload
		let onload_code = `
		let { ${GamePreview.engine_classes} } = game_instance;
		${this.getExtraEngineCode()}\n`;

		let code = `
var game_instance = Blanke("#game",{
	config: ${JSON.stringify(app.project_settings)},
	fill_parent: true,
	ide_mode: true,
	${this.options.size == null ?
	`auto_resize: true,
	resizable: true,`
	:
	`width: ${this.options.size[0]},
	height: ${this.options.size[1]},`
	}
	root: '${app.cleanPath(nwPATH.relative("src",nwPATH.join(app.project_path)))}',
	//background_color: 0x485358,
	assets: [${this.getAssetStr()}],
	onLoad: function(classes){
		let { ${GamePreview.engine_classes} } = classes;
		${this.getExtraEngineCode()}\n`;
		this.line_ranges = {};
		let line_offset = 22; // compensates for line 308 where extra code is added;
		let last_line_end = (code.match(re_new_line) || []).length + line_offset;
		for (let path of scripts) {
			if (nwFS.pathExistsSync(path)) {
				let file_data = nwFS.readFileSync(path,'utf-8') + '\n';
				// breakpoints
				if (path == current_script) {
					let lines = file_data.split('\n')
					this.breakpoints.forEach((l)=>{
						lines[l] = '(()=>{Game.pause();'+lines[l]+'})();';
						// lines.splice(l,0,'Game.pause()');
					})
					code += lines.join('\n');
				} else 
					code += file_data;
				onload_code += nwFS.readFileSync(path,'utf-8') + '\n';
				// get the lines at which this piece of code starts and ends
				this.line_ranges[path] = {
					start: last_line_end,
					end: (code.match(re_new_line) || []).length + line_offset
				};
				
				last_line_end = this.line_ranges[path].end;
			}
		}
		onload_code += (post_load || '');
		code += (post_load || '') + `
	}
});`;
		this.iframe.srcdoc = getHTML(`
	<body>
		<div id="game"></div>
	</body>
	<script class="source">
	</script>`, this.options.ide_mode);

		this.last_code = `
		let app = window.parent.app;
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
		${code}
		`;

		return onload_code;
	}
	
	setSourceFile (file) {
		this.last_script = file;
		if (!this.paused)
			this.refreshSource(this.last_script);
	}

	refreshEngine () {
		if (!this.paused)
			this.refreshSource(this.last_script);
		/*
		let iframe = this.iframe;
		blanke.destroyElement(iframe.contentDocument.querySelector('script[src="../blankejs/blanke.js"]'));
		var head= iframe.contentDocument.getElementsByTagName('head')[0];
		var script= iframe.contentDocument.createElement('script');
		script.src= '../blankejs/blanke.js';
		head.appendChild(script);*/
	}
}
GamePreview.engine_classes = '';
