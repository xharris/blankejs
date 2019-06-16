let getHTML = (body) => {
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
		}
		#game {
			width: 100%;
			height: 100%;
		}
		body > img {
			width: 100%;
			height: 100%;
		}
	</style>
	<head>
		<script type="text/javascript">${app.engine_code}</script>
	</head>
	${body}
</html>
`};
let re_scene_name = /\bScene\s*\(\s*[\'\"](.+)[\'\"]/;
let re_new_line = /(\r\n|\r|\n)/g;

class GamePreview {
	constructor (parent, opt) {
		let this_ref = this;

		this.game = null;
		this.container = app.createElement("iframe");
		this.id = "game-"+guid();
		this.container.id = this.id;
		this.parent = parent || document.createDocumentFragment();
		this.line_ranges = {};

		this.options = ifndef_obj(opt, {
			test_scene: true,
			scene: null,
			size: null,
			onLoad: null
		});
		
		// engine loaded
		this.refresh_file = null;
		this.errored = false;
		this.container.addEventListener('load', () => {
			this.game = this.container.contentWindow.game;
			
			if (this.errored) {
				return;
			}

			if (this.refresh_file) {
				this.refreshSource(this.refresh_file);
			}
			else if (this.last_script) {
				this.refreshSource(this.last_script);
			}
			else {
				this.refreshSource();
			}	
			if (this.options.onLoad)
				this.options.onLoad(this);
		})
		this.refreshSource();
		if (!(this.refresh_file || this.last_script))
			this.refreshSource();
		this.parent.appendChild(this.container);

		this.paused = false;
		document.addEventListener('engineChange',(e)=>{
			if (!this.paused || this.errored)
				this.refreshEngine();	
		});
	}

	get width () {
		if (this.game) return this.game.Game.width;
	}

	get height () {
		if (this.game) return this.game.Game.height;
	}
	
	pause () {
		this.paused = true;
		if (this.game)
			this.game.Game.pause();
	}

	resume () {
		this.paused = false;
		if (this.game && !this.errored)
			this.game.Game.resume();
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
				return false;
			});
			var game = Blanke("#game",{
				config: ${JSON.stringify(app.project_settings)},
				fill_parent: false,
				width: ${this.options.size[0]},
				height: ${this.options.size[1]},
				background_color: 0x485358
			});
			window.addEventListener('load', function(e) {
				${this.refreshSource()}
			});
		</script>`);
	}

	refreshDoc (extra_code) {
		// add iframe content
		this.container.srcdoc = getHTML(`
	<body>
		<div id="game"></div>
	</body>
	<script>
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
		var game = Blanke("#game",{
			config: ${JSON.stringify(app.project_settings)},
			fill_parent: true,
			ide_mode: true,
			${this.options.size == null ?
			`auto_resize: true,`
			:
			`width: ${this.options.size[0]},
			height: ${this.options.size[1]},`
			}
			root: '${app.cleanPath(nwPATH.relative("src",nwPATH.join(app.project_path)))}',
			background_color: 0x485358
		});
		${extra_code}
	</script>`);
	}
	
	refreshSource (current_script, new_doc) {
		if (this.errored) {	
			this.errored = false;
		}
		this.last_script = current_script;
		if (!this.game) 
			this.refresh_file = current_script;
		if (this.refresh_file) {
			current_script = this.refresh_file
			this.refresh_file = null;
		}
		let post_load = '';
		// get all the scripts
		let scripts = [];
		let curr_script_cat = 'other';
		for (let cat of ['entity','scene','other']) {
			if (Array.isArray(Code.scripts[cat])) {
				// put current_script at end
				let new_scripts = Code.scripts[cat];
				if (current_script) {
					let found = false;
					new_scripts = new_scripts.filter((val) => {
						if (val == current_script) {
							found = true;
							curr_script_cat = cat;
						}
						return val != current_script;
					});
					if (found)
						scripts.push(current_script);
				}
				scripts = scripts.concat(new_scripts);
			}
		}

		switch (curr_script_cat) {
			case 'entity':
				if (this.options.test_scene)
					post_load += '\nScene.start("_test");\n';
				break;
			case 'scene':
				let match = re_scene_name.exec(nwFS.readFileSync(current_script,'utf-8'));
				if (match && match.length > 1)
					post_load += `\nScene.start("${match[1]}");\n`;
				break;
			case 'other':
				if (this.options.scene)
					post_load += '\nScene.start("'+this.options.scene+'");\n';
				break;
		}

		// wrapped in a function so local variables are destroyed on reload
		let code = `
(function(){ //window.addEventListener("load",function(){
	let { Asset, Draw, Entity, Game, Hitbox, Input, Map, Scene, Sprite, Util, View } = game;
	let TestScene = (funcs) => {
	${this.options.test_scene ? `
		Scene.ref["_test"] = null;
		Scene("_test", funcs);
	`
	: ''}
	}
`;
		let re
		this.line_ranges = {};
		let last_line_end = (code.match(re_new_line) || []).length;
		for (let path of scripts) {
			code += nwFS.readFileSync(path,'utf-8') + '\n';
			// get the lines at which this piece of code starts and ends
			this.line_ranges[path] = {
				start: last_line_end,
				end: (code.match(re_new_line) || []).length
			};
			
			last_line_end = this.line_ranges[path].end;
		}
		code += (post_load || '') + `
})(); //});`;
		if (this.game) this.game.Game.end();
		if (!this.game || new_doc) {
			this.refreshDoc(code);
		}

		// reload source file
		let iframe = this.container;
		let doc = iframe.contentDocument;

		if (this.game && doc) {
			let old_script = doc.querySelectorAll('script.source');
			if (old_script)
				old_script.forEach((el) => el.remove());
			let parent= doc.getElementsByTagName('body')[0];
			let script= doc.createElement('script');
			script.classList.add("source");
			script.innerHTML= code;

			iframe.contentWindow.onerror = (msg, url, lineNo, columnNo, error) => {
				this.pause();
				this.errored = true;
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
				return true;
			}
			if (this.onRefresh) this.onRefresh();
			if (this.onLog) {
				iframe.contentWindow.console = {
					log:  (...args) => {
						this.onLog(args)
						//old_log(...args);
					}
				}
			}
			parent.appendChild(script);
		}
		return code;
	}

	refreshEngine () {
		if (!this.paused)
			this.refreshSource(this.last_script, true);
		/*
		let iframe = this.container;
		blanke.destroyElement(iframe.contentDocument.querySelector('script[src="../blankejs/blanke.js"]'));
		var head= iframe.contentDocument.getElementsByTagName('head')[0];
		var script= iframe.contentDocument.createElement('script');
		script.src= '../blankejs/blanke.js';
		head.appendChild(script);*/
	}
}