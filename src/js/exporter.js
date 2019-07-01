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
			if (cb) cb(js_path, this.toast);
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
	onLoad: function(){
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
		if (this.toast) {
			this.toast.icon = 'check-bold';
			this.toast.style = 'good';
			this.toast.text = "Export done! <a href='#' onclick='Exporter.openDistFolder(\""+os+"\");'>View files</a>";
			this.toast.die(8000);
		}
	}

	export (target_os) {
		let this_ref = this;
		let os_dir = nwPATH.join(app.project_path,"dist",target_os);
		let engine_path = app.settings.engine_path;
		let project_name = app.project_settings.export.name;

		blanke.toast("Starting export for "+target_os);

		nwFS.emptyDir(os_dir, function(err){
			// move assets
			nwFS.copySync(app.getAssetPath(), nwPATH.join(os_dir, 'assets'));
			// create js file
			this_ref.createJS(os_dir, target_os, function(js_path){
				if (target_os == "love") {
					this_ref.doneToast("love");
				}

				// export to WINDOWS
				if (target_os == "windows") {
					let exec_cmd = '';
					let exe_path = nwPATH.join(os_dir, project_name+".exe");

					// TODO: test on mac/linux
					// copy /b love.exe+game.love game.exe
					let f_loveexe = nwFS.createReadStream(nwPATH.join(engine_path,"love.exe"), {flags:'r', encoding:'binary'});
					let f_gamelove = nwFS.createReadStream(love_path, {flags:'r', encoding:'binary'});
					let f_gameexe = nwFS.createWriteStream(exe_path, {flags:'w', encoding:'binary'});
					// set up callbacks
					f_loveexe.on('end', ()=>{ f_gamelove.pipe(f_gameexe, {end:false}); })
					f_gamelove.on('end', ()=>{ f_gameexe.end(''); })
					// start merging
					f_loveexe.pipe(f_gameexe, {end:false});
					// finished all merging
					f_gameexe.on('finish', () => {
						nwFS.removeSync(love_path);
						// copy dlls and stuff
						nwFS.copySync(engine_path,os_dir,{filter:function(path){
							path = path.replace(process.cwd(),"");
							let exclude = [".app",".exe",/[\\\/]lua([\\\/]|\b)/];

							for (let e of exclude) {
								if (path.match(e)) {
									return false;
								}
							}
							return true;
						}});
		
						this_ref.doneToast("windows");
					});
				}

				// exporting to MAC
				if (target_os == "mac") {
					let app_path = nwPATH.join(os_dir,project_name+".app");
					nwFS.copySync(nwPATH.join(engine_path,"love.app"), app_path);
					nwFS.moveSync(love_path, nwPATH.join(app_path,"Contents","Resources",project_name+".love"));
					// make replacements in Info.plist
					nwFS.readFile(nwPATH.join(app_path,"Contents","Info.plist"), {encoding:'utf-8'}, function(err, data){
						if (err) { console.error(err); return; }

						data = data.replaceAll("org.love2d.love", "com.XHH."+project_name);
						data = data.replaceAll(/L\u00D6VE/g, project_name);
						data = data.replaceAll(/<key>UTExportedTypeDeclarations<\/key>\s*<array>[\s\S]+<\/array>/g, "");

						// change icon
						nwFS.copySync(app.project_settings.icns, nwPATH.join(app_path,"Contents","Resources","GameIcon.icns"));
						nwFS.copySync(app.project_settings.icns, nwPATH.join(app_path,"Contents","Resources","OS X AppIcon.icns"));
						// nwFS.copySync(app.project_settings.icns, nwPATH.join(app_path,"Contents","Resources","Document.icns"));

						nwFS.writeFile(nwPATH.join(app_path,"Contents","Info.plist"), data, function(err){
							if (err) { console.error(err); return; }
							this_ref.doneToast("mac")
						});
					})
				}

				// exporting to LINUX
				if (target_os == "linux") {
					// just keep it as a .love
					this_ref.doneToast("linux");
				}

				// exporting to WEB
				if (target_os == "web") {
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
					nwFS.writeFile(nwPATH.join(os_dir,'index.html'),str_html,'utf-8',()=>{
						this_ref.doneToast('web');
					});
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
