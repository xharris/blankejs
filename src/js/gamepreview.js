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

class GamePreview {
	constructor (parent) {
		let this_ref = this;

		this.game = null;
		this.container = app.createElement("iframe");
		this.id = "game-"+guid();
		this.container.id = this.id;
		this.parent = parent;
		this.line_offset = 0;
		
		// engine loaded
		this.refresh_file = null;
		this.container.onload = () => {
			this.game = this.container.contentWindow.game;
			if (this.extra_onload) {
				this.extra_onload();
				this.extra_onload = null;
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
	
	pause () {
		if (this.game)
			this.game.Game.pause();
	}

	resume () {
		if (this.game)
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
//if (game)
	(function(){\nlet { Asset, Draw, Entity, Game, Hitbox, Input, Map, Scene, Sprite, Util, View } = game;
	let TestScene = (funcs) => {
		Scene.ref["_test"] = null;
		Scene("_test", funcs);
	}
`;
		this.line_offset = 0;
		for (let path of scripts) {
			if (path == current_script) {
				this.line_offset = (code.match(/\n/g) || '').length;
			}
			code += nwFS.readFileSync(path,'utf-8') + '\n';
		}
		code += (post_load || '') + '})();';
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

		parent.onerror = (msg, url, lineNo, columnNo, error) => {
			if (this.onError) this.onError(msg, url, lineNo - this.line_offset, columnNo, error);
			return true;
		}
		/*
		iframe.contentWindow.console.log = () => {

		}*/
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