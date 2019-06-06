let getHTML = (body) => `
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
		<script src="../blankejs/pixi.min.js"></script>
		<script src="../blankejs/SAT.min.js"></script>
		<script src="../blankejs/blanke.js"></script>
	</head>
	${body}
</html>
`;
let re_scene_name = /\bScene\s*\(\s*[\'\"](.+)[\'\"]/;
let re_new_line = /(\r\n|\r|\n)/g;

class GamePreview {
	constructor (parent) {
		let this_ref = this;

		this.game = null;
		this.container = app.createElement("iframe");
		this.id = "game-"+guid();
		this.container.id = this.id;
		this.parent = parent;
		this.line_ranges = {};
		
		// engine loaded
		this.refresh_file = null;
		this.container.onload = () => {
			this.game = this.container.contentWindow.game;
			if (this.extra_onload) {
				this.extra_onload();
			}
			if (this.refresh_file) {
				this.refreshSource(this.refresh_file);
			}
			else if (this.last_script) {
				this.refreshSource(this.last_script);
			}
		}
		this.refreshDoc();
		if (parent)
			parent.appendChild(this_ref.container);

		document.addEventListener('engineChange',(e)=>{
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
		if (this.game)
			this.game.Game.pause();
	}

	resume () {
		if (this.game && !this.errored)
			this.game.Game.resume();
	}

	refreshDoc () {
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
			auto_resize: true,
			root: '${app.cleanPath(nwPATH.relative("src",nwPATH.join(app.project_path)))}',
			background_color: 0x485358
		});
	</script>`);
	}
	
	refreshSource (current_script) {
		if (this.errored) {	
			this.errored = false;
			this.refreshDoc();
		}
		this.last_script = current_script;
		if (!this.game) {
			this.refresh_file = current_script;
			return;
		};
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
				post_load += '\nScene.start("_test");\n';
				break;
			case 'scene':
				let match = re_scene_name.exec(nwFS.readFileSync(current_script,'utf-8'));
				if (match && match.length > 1)
					post_load += `\nScene.start("${match[1]}");\n`;
				break;
		}

		// wrapped in a function so local variables are destroyed on reload
		let code = `
(function(){
	let { Asset, Draw, Entity, Game, Hitbox, Input, Map, Scene, Sprite, Util, View } = game;
	let TestScene = (funcs) => {
		Scene.ref["_test"] = null;
		Scene("_test", funcs);
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
})();`;
		this.game.Game.end();

		// reload source file
		let iframe = this.container;
		let doc = iframe.contentDocument;
		let old_script = doc.querySelectorAll('script.source');
		if (old_script)
			old_script.forEach((el) => el.remove());
		let parent= doc.getElementsByTagName('body')[0];
		let script= doc.createElement('script');
		script.classList.add("source");
		script.innerHTML= code;

		iframe.contentWindow.onerror = (msg, url, lineNo, columnNo, error) => {
			this.errored = true;
			this.pause();
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

	refreshEngine () {
		if (this.game) this.game.Game.end();
		 
		this.refreshDoc();
		/*
		let iframe = this.container;
		blanke.destroyElement(iframe.contentDocument.querySelector('script[src="../blankejs/blanke.js"]'));
		var head= iframe.contentDocument.getElementsByTagName('head')[0];
		var script= iframe.contentDocument.createElement('script');
		script.src= '../blankejs/blanke.js';
		head.appendChild(script);*/
	}
}

let engine_watch;
window.addEventListener('load',(e)=>{
	engine_watch = nwFS.watch(nwPATH.join('blankejs','blanke.js'), (e) => {
		dispatchEvent('engineChange');
	});
})