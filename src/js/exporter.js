class Exporter extends Editor {
	constructor (...args) {
		super(...args);

		if (DragBox.focus('Exporter')) return;

		// setup default settings
		if (!app.project_settings.export) app.project_settings.export = {};
		ifndef_obj(app.project_settings.export, {
			name: nwPATH.basename(app.project_path)
		});

		this.setupDragbox();
		this.setTitle('Exporter');
		this.removeHistory();
		this.hideMenuButton();

		this.container.width = 400;
		this.container.height = 350;

		var this_ref = this;

		this.platforms = ['windows','mac','linux','love'];

		this.el_platforms = app.createElement("div","platforms");
		let el_title1 = app.createElement("p","title1");
		el_title1.innerHTML = "One-click export";
		this.el_platforms.appendChild(el_title1);
		
		this.platforms.forEach(function(platform){
			let el_platform_container = app.createElement("button",["ui-button-rect","platform",platform]);
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
	}

	createLove (dir, cb) {
		let love_path = nwPATH.join(dir, app.project_settings.export.name+".love");
		let engine_path = app.settings.engine_path;

		let output = nwFS.createWriteStream(love_path);
		let archive = nwZIP('zip',{
			// zlib: { level: 9 }
		});

		output.on('close', function(){
			// done
			if (cb) cb(love_path);
		});
		archive.pipe(output);
		archive.glob("**/*",{
			cwd: nwPATH.join(engine_path,"lua")
		})
		archive.glob("**/*",{
			cwd: app.project_path,
			ignore: ["dist","dist/**/*"]
		});
		archive.finalize();
	}

	static openDistFolder(os) {
		nwGUI.Shell.openItem(nwPATH.join(app.project_path,"dist",os));
	}

	doneToast (os) {
		blanke.toast("Export done! <a href='#' onclick='Exporter.openDistFolder(\""+os+"\");'>View files</a>", 8000);
	}

	export (target_os) {
		let this_ref = this;
		let os_dir = nwPATH.join(app.project_path,"dist",target_os);
		let engine_path = app.settings.engine_path;
		let project_name = app.project_settings.export.name;

		blanke.toast("Starting export for "+target_os, 1000);
	
		nwFS.emptyDir(os_dir, function(err){

			// create a LOVE file
			this_ref.createLove(os_dir, function(love_path){
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

						data = data.replace("org.love2d.love", "com.XHH."+project_name);
						data = data.replace(/L\u00D6VE/g, project_name);
						data = data.replace(/<key>UTExportedTypeDeclarations<\/key>\s*<array>[\s\S]+<\/array>/g, "");

						nwFS.writeFile(nwPATH.join(app_path,"Contents","Info.plist"), data, function(err){
							if (err) { console.error(err); return; }
							this_ref.doneToast("mac")
						});
					})
				}

				// exporting to LINUX
				// ... just keep the .love file I guess (TODO: look into AppImages)
			});

		});
	}
}

document.addEventListener("openProject", function(e){
	app.removeSearchGroup("exporter");
	app.addSearchKey({key: 'Export game', onSelect: function() {
		new Exporter(app);
	}});
});