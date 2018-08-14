class Exporter extends Editor {
	constructor (...args) {
		super(...args);

		if (DragBox.focus('Exporter')) return;

		this.setupDragbox();
		this.setTitle('Exporter');
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
		let love_path = nwPATH.join(dir, app.settings.export.name+".love");

		let output = nwFS.createWriteStream(love_path);
		let archive = nwZIP('zip',{
			zlib: { level: 9 }
		});

		output.on('close', function(){
			// done
			if (cb) cb(love_path);
		});
		archive.pipe(output);
		archive.glob("**/*",{
			cwd: nwPATH.join("love2d","lua")
		})
		archive.glob("**/*",{
			cwd: app.project_path,
			ignore: ["dist","dist/**/*"]
		});
		archive.finalize();
	}

	export (target_os) {
		let this_ref = this;
		let os_dir = nwPATH.join(app.project_path,"dist",target_os);
		let project_name = app.settings.export.name;

		nwFS.emptyDir(os_dir, function(err){

			// create a LOVE file
			this_ref.createLove(os_dir, function(love_path){
				// export to WINDOWS
				if (target_os == "windows") {
					let exec_cmd = '';
					// currently on MAC/LINUX
					if (app.os == "mac" || app.os == "linux") {
						exec_cmd = "cat "+nwPATH.join("love2d","love.exe")+" "+love_path+" > "+nwPATH.join(os_dir, project_name+".exe");
					}
					// currently on WINDOWS
					if (app.os == "win") {
						exec_cmd = "copy /b "+nwPATH.join("love2d","love.exe")+"+"+love_path+" "+nwPATH.join(os_dir, project_name+".exe");
					}

					exec(exec_cmd, (err, stdout, stderr) =>{
						if (err) {
							console.error(err);
							return;
						}

						//nwFS.removeSync(love_path);
						nwFS.copySync("love2d",os_dir,{filter:function(path){
							path = path.replace(process.cwd(),"");
							console.log(path)
							let exclude = ["love.app","love.exe","lovec.exe",/[\\\/]lua/g];

							for (let e of exclude) {
								if (path.includes(e)) {
									return false;
								}
							}
							return true;
						}});
		
						blanke.toast("Export done!");
					});
				}

				// exporting to MAC
				if (target_os == "mac") {
					nwFS.copySync(nwPATH.join("love2d","love.app"), nwPATH.join(os_dir,project_name+".app"));
					nwFS.moveSync(love_path, nwPATH.join(os_dir,project_name+".app","Contents","Resources",project_name+".love"));
					// make replacements in Info.plist
					nwFS.readFile(nwPATH.join(os_dir,project_name+".app","Contents","Info.plist"), {encoding:'utf-8'}, function(err, data){
						if (err) { console.error(err); return; }

						data.replace("org.love2d.love", "com.XHH."+project_name);
						data.replace("LÖVE", project_name);
						data.replace(/<key>UTExportedTypeDeclarations<\/key>\s*<array>[\s\S]+<\/array>/g, "");

						nwFS.writeFile(nwPATH.join(os_dir,project_name+".app","Contents","Info.plist"), data, function(err){
							if (err) { console.error(err); return; }
							blanke.toast("Export done!");
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

	// add default settings
	if (!app.settings.export) app.settings.export = {};
	ifndef_obj(app.settings.export, {
		name: nwPATH.basename(app.project_path)
	});
});