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

	createLove (dir) {
		let love_path = nwPATH.join(dir, app.settings.export.name+".love");

		let output = nwFS.createWriteStream(love_path);
		let archive = nwZIP('zip',{
			zlib: { level: 9 }
		});

		output.on('close', function(){
			// done 
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

		return love_path
	}

	export (target_os) {
		let this_ref = this;
		let os_dir = nwPATH.join(app.project_path,"dist",target_os);
		nwFS.emptyDir(os_dir, function(err){

			// create a LOVE file
			let love_path = this_ref.createLove(os_dir);

			// export to WINDOWS
			if (target_os == "windows") {
				// currently on MAC/LINUX
				if (app.os == "mac" || app.os == "linux") {
					exec("cat "+nwPATH.join("love2d","love.exe")+" "+love_path+" > "+nwPATH.join(os_dir, app.settings.export.name+".exe"), (err, stdout, stderr) =>{
						if (err) {
							console.error(err);
							return;
						}

						nwFS.removeSync(love_path);
						nwFS.copySync("love2d",os_dir,{filter:function(path){
							console.log(path)
						}})
					});
				}
			}
		});
		
		blanke.toast("done");
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