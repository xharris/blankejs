var re_resolution = /resolution[\s=]*(?:(\d+)|{([\d\s]+),([\s\d]+)})/;

class Exporter extends Editor {
	constructor (...args) {
		super(...args);
		let this_ref = this;

		if (DragBox.focus('Exporter')) return;

		this.setupDragbox();
		this.setTitle('Exporter');
		this.removeHistory();
		this.hideMenuButton();

		this.container.width = 400;
		this.container.height = 370;

		// diplay list of target platforms
		this.platforms = ['web','windows','mac','linux'];

		this.el_platforms = app.createElement("div","platforms");
		let el_title1 = app.createElement("p","title1");
		el_title1.innerHTML = "One-click export";
		this.el_platforms.appendChild(el_title1);
		
		this.platforms.forEach(function(platform){
			let el_platform_container = app.createElement("button",["ui-button-rect","platform",platform]);

			if (platform == 'web') {
				el_platform_container.classList.add('danger');
				el_platform_container.title = "experimental feature!";
			}

			let el_platform_icon = app.createElement("img","icon");
			el_platform_icon.src = "icons/"+platform+".png";

			el_platform_container.value = platform;
			el_platform_container.addEventListener('click', function(e){
				this_ref.export(e.target.value);
			});

			el_platform_container.appendChild(el_platform_icon);
			this_ref.el_platforms.appendChild(el_platform_container);
		});

		this.appendChild(this.el_platforms);

		// setup default settings
		if (!app.project_settings.export) app.project_settings.export = {};
		ifndef_obj(app.project_settings.export, {
			name: nwPATH.basename(app.project_path),
			remove_unused: true,
			web_autoplay: false,
			minify: true
		});

		// extra options
		let form_options = [
			['general'],
			['name', 'text', {'default':app.project_settings.export.name}],
			//['remove_unused','checkbox',{'default':app.project_settings.export.remove_unused,label:"remove unused classes"}],
			['web'],
			['web_autoplay','checkbox',{'default':app.project_settings.export.web_autoplay,label:"autoplay"}],
			['minify','checkbox',{'default':app.project_settings.export.minify}]
		];
		this.el_export_form = new BlankeForm(form_options);
		this.el_export_form.container.classList.add("dark");
		form_options.forEach((s)=>{
			if (s.length > 1)
				this_ref.el_export_form.onChange(s[0],(val)=>app.project_settings.export[s[0]] = val);
		});
		this.appendChild(this.el_export_form.container);
	}

	createJS (dir, target_os, cb) {
		let js_path = nwPATH.join(dir, app.project_settings.export.name+".js");
		let engine_path = app.settings.engine_path;

		this.toast = blanke.toast(`Building JS file`,1000000);
		this.toast.icon = 'dots-horizontal';
		this.toast.style = 'wait';
		let game = new GamePreview();
		let scripts = GamePreview.getScriptOrder();
		let user_code = '';
		for (let path of scripts) {
			user_code += nwFS.readFileSync(path,'utf-8') + '\n';
		}
		app.minifyEngine((code)=>{
			nwFS.writeFileSync(js_path,code,'utf-8');
			let str_html = `
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
		<script type="text/javascript" src="${nwPATH.basename(js_path)}"></script>
	</head>
	<body>
		<div id="game"></div>
	</body>
	<script>
		Blanke.run('#game','${app.project_settings.export.name}');
	</script>
</html>`
			nwFS.writeFileSync(nwPATH.join(dir,'index.html'),str_html,'utf-8');
			if (cb) cb(js_path);
		},{ 
			silent: true,
			minifiy: app.project_settings.export.minify, // true,
			wrapper: (code) => `
${code}

if (!Blanke.game_options)
	Blanke.game_options = {};
if (!Blanke.run) {
	Blanke.run = (selector, name) => {
		Blanke(selector, Blanke.game_options[name])
	}
}
Blanke.game_options['${app.project_settings.export.name}'] = {
	config: ${JSON.stringify(app.project_settings)},
	width: ${app.project_settings.size[0]},
	height: ${app.project_settings.size[1]},
	assets: [${game.getAssetStr()}],
	onLoad: function(classes){
		let { ${GamePreview.engine_classes} } = classes;
		let TestScene = () => {};
		${user_code}
	}
};
`	 
		})
		app.project_settings.os = target_os; // why ?
	}

	static openDistFolder(os) {
		elec.shell.openItem(nwPATH.join(app.project_path,"dist",os));
	}

	doneToast (os) {
		if (this.temp_dir)
			nwFS.removeSync(this.temp_dir);
		if (this.toast) {
			this.toast.icon = 'check-bold';
			this.toast.style = 'good';
			this.toast.text = "Export done! <a href='#' onclick='Exporter.openDistFolder(\""+os+"\");'>View files</a>";
			this.toast.die(8000);

			app.notify({
				title: 'Export complete!',
				body: `\\(^o^)/`,
				onclick: () => {
					Exporter.openDistFolder(os);
				}
			})
		}
	}

	/*
		darwin: game.app/Contents/Resources/app
		- darwin-x64
		linux: resources/app
		- linux-arm64
		- linux-ia32
		- linux-armv7l
		- linux-x64
		mas: game.app/Contents/Resources/app
		- mas-x64
	*/

	export (target_os) {
		let this_ref = this;
		let bin_dir = nwPATH.join('src','binaries');
		let temp_dir = target_os == 'web' ? os_dir : nwPATH.join(app.project_path,'dist','temp');
		let os_dir = nwPATH.join(app.project_path,"dist",target_os);
		let engine_path = app.settings.engine_path;
		let project_name = app.project_settings.export.name;

		if (target_os != 'web') {
			this.temp_dir = temp_dir;
		} else 
			this.temp_dir = null;
		nwFS.removeSync(temp_dir);

		blanke.toast("Starting export for "+target_os);

		let setupBinaries = (binary_list, app_dir) => {
			this.toast.text = "Extracting binary";
			let zip = new nwZIP2('./src/binaries.zip');
			let entries = zip.getEntries();
			
			for (let bin of binary_list) {
				let extracted = {};
				entries.forEach(entry => {
					let name = entry.entryName;
					if (name.startsWith(bin) &&
						!name.includes('.DS_Store') && 
						!extracted[name]) {

						extracted[name] = true;
						console.log(name);
						try {
							zip.extractEntryTo(name,os_dir);
						} catch (e) {}
					}
				});
				// move app folder into resources folder
				this.toast.text = "Copying game code";
				nwFS.moveSync(temp_dir, app_dir.replace('<BINARY>',bin));
			}
		}
		nwFS.emptyDir(os_dir, function(err){
			// move assets
			nwFS.copySync(app.getAssetPath(), nwPATH.join(temp_dir, 'assets'));
			// entry.js
			nwFS.writeFileSync(nwPATH.join(temp_dir,'entry.js'),`
const elec = require('electron');

elec.app.on('ready', function(){
    let main_window = new elec.BrowserWindow({
        width: ${app.project_settings.size[0]},
        height: ${app.project_settings.size[1]}
    })
    main_window.loadFile('index.html');
});
			`,'utf-8');
			// package.json
			nwFS.writeFileSync(nwPATH.join(temp_dir,'package.json'),`
{
	"name": "${app.project_settings.export.name}",
	"description": "Made with BlankE",
	"version": "1.0",
	"main": "app/entry.js",
	"chromium-args": "--enable-webgl --ignore-gpu-blacklist"
}
			`,'utf-8');
			// create js file
			this_ref.createJS(temp_dir, target_os, function(){	
				if (target_os != 'web') 
					this_ref.toast.text = "Building app";

				// export to WINDOWS
				if (target_os == "windows") {
					
				}

				// exporting to MAC
				if (target_os == "mac") {

					setupBinaries(
						['darwin-x64'], 
						nwPATH.join(os_dir,`<BINARY>`,'game.app','Contents','Resources','app')
					);

					

					this_ref.doneToast('mac');
				}

				// exporting to LINUX
				if (target_os == "linux") {
					// just keep it as a .love
					this_ref.doneToast("linux");
				}

				// exporting to WEB
				if (target_os == "web") {
					this_ref.doneToast('web');
				}
			});

		});
	}
}

document.addEventListener("openProject", function(e){
	app.removeSearchGroup("Exporter");
	app.addSearchKey({key: 'Export game', group:"Exporter", onSelect: function() {
		new Exporter(app);
	}});
});
