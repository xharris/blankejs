var re_resolution = /resolution[\s=]*(?:(\d+)|{([\d\s]+),([\s\d]+)})/;
const DEFAULT_EXPORT_SETTINGS = () => ({
	name: nwPATH.basename(app.project_path),
	/*
	web_autoplay: false,
	scale_mode: 'linear',
	frameless: false,
	minify: true,
	scale: true,
	resizable: false*/
});

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
		this.platforms = Object.keys(engine.export_targets || []);

		this.el_platforms = app.createElement("div","platforms");
		let el_title1 = app.createElement("p","title1");
		el_title1.innerHTML = "One-click export";
		this.el_platforms.appendChild(el_title1);
		
		this.platforms.forEach(function(platform){
			let el_platform_container = app.createElement("button",["ui-button-rect","platform",platform]);
			el_platform_container.title = platform;

			let el_platform_icon = app.createElement("object");
			el_platform_icon.type = "image/svg+xml";
			el_platform_icon.data = "icons/"+platform+".svg";

			el_platform_container.value = platform;
			el_platform_container.addEventListener('click', function(e){
				this_ref.export(e.target.value);
			});

			el_platform_container.appendChild(el_platform_icon);
			this_ref.el_platforms.appendChild(el_platform_container);
		});

		this.appendChild(this.el_platforms);

		// setup default settings
		if (!app.projSetting("export")) app.projSetting("export",{})
		ifndef_obj(app.projSetting("export"), DEFAULT_EXPORT_SETTINGS());

		// extra options
        let engine_settings = [];
        if (engine.export_settings) {
            for (let form_set of engine.export_settings) {
                engine_settings.push(form_set);
            }
        }
		let form_options = [
			['general'],
			['name', 'text', {'default':app.projSetting("export").name}],
			...engine_settings,
		];
		/*
		for (let set of form_options) {
			if (set.length >= 2 && typeof(set[1]) != "boolean" && !set.some(i => typeof(i) == 'object'))
				set.push({});
			for (let prop of set) {
				if (typeof(prop) == "object" && prop.default == null)
					props.default = app.projSetting("export")[set[0]];
			}
		}*/
		this.el_export_form = new BlankeForm(form_options, true);
		this.el_export_form.useValues(app.projSetting("export"));
		this.el_export_form.container.classList.add("dark");
		form_options.forEach((s)=>{
			if (s.length > 1 && typeof(s[1]) != "boolean")
				this_ref.el_export_form.onChange(s[0],(val)=>app.projSetting("export")[s[0]] = val);
		});
		this.appendChild(this.el_export_form.container);
	}

	// dir : target directory to write bundled files to 
	bundle (dir, target_os, cb_done) {
		if (engine.bundle)
			engine.bundle(dir, target_os, cb_done);
	}

	static openDistFolder(os) {
		let path = nwPATH.join(app.project_path,"dist",os);
		elec.shell.openItem(path);
		elec.clipboard.writeText(path);
	}

	doneToast (os) {
		process.noAsar = false;
		if (this.temp_dir)
			nwFS.removeSync(this.temp_dir);
		if (this.toast) {
			this.toast.icon = 'check-bold';
			this.toast.style = 'good';
			this.toast.text = "Export done! <a href='#' onclick='Exporter.openDistFolder(\""+os+"\");'>View files</a>";
			this.toast.die(8000);

			app.notify({
				title: 'Export complete!',
				body: `\\( ^o^ )/`,
				onclick: () => {
					Exporter.openDistFolder(os);
				}
			})
		}
	}

	errToast () {
		process.noAsar = false;
		if (this.temp_dir)
			nwFS.removeSync(this.temp_dir);
		
		if (this.toast) {
			this.toast.icon = 'close';
			this.toast.style = 'bad';
			this.toast.text = "Export failed!";
			this.toast.die(8000);

			app.notify({
				title: 'Export failed!',
				body: `( -_-")`,
				onclick: () => {
					Exporter.openDistFolder(os);
				}
			})
		}
	}

	/*
		darwin
		- darwin-x64
		linux
		- linux-arm64
		- linux-ia32
		- linux-armv7l
		- linux-x64
		mas (mac app store)
		- mas-x64
	*/

	export (target_os) {
		let this_ref = this;
		let os_dir = nwPATH.join(app.project_path,"dist",target_os);
		let temp_dir = engine.export_targets[target_os] === false ? os_dir : nwPATH.join(app.project_path,'dist','temp');

		if (engine.export_targets[target_os] !== false) {
			this.temp_dir = temp_dir;
		} else 
			this.temp_dir = null;
		nwFS.removeSync(temp_dir);

		blanke.toast("Starting export for "+target_os);

		let setupBinary = async (binary_list) => {
			let platforms = binary_list.reduce((a, c) => {
				let [ plat, arch ] = c.split('-');
				if (!a[plat]) a[plat] = [];
				if (!a[plat].includes(arch)) a[plat].push(arch);
				return a; 
			},{});
			binary_list.forEach((c) => {
				c = c.split('-');
				if (!platforms[c[0]].includes(c[1])) platforms[c[0]].push(c[1]);
			});
			// iterate platforms
			let cb_done = () => {
				this.doneToast(target_os);
			};
			let cb_err = (err) => {
				app.error(err)
				this.errToast();
			}
			for (let platform in platforms) {
				if (engine.setupBinary)
					engine.setupBinary(os_dir, temp_dir, platform, platforms[platform], cb_done, cb_err);
			}
		}

		this.toast = blanke.toast('Removing old files',-1);
		this.toast.icon = 'dots-horizontal';
		this.toast.style = 'wait';

		process.noAsar = true;
		nwDEL([os_dir],{ force: true })
			.then(() => {
				nwFS.ensureDirSync(os_dir);
				// move assets
				if (engine.export_assets !== false)
					nwFS.copySync(app.getAssetPath(), nwPATH.join(temp_dir, 'assets'));
				let extra_assets = engine.extra_bundle_assets || [];
				for (let a of extra_assets)
					nwFS.copySync(nwPATH.join(app.project_path, a), nwPATH.join(temp_dir, a));

				if (engine.preBundle)
					engine.preBundle(temp_dir, target_os);
				// create js file		
				this.toast.text = `Bundling files`
				this_ref.bundle(temp_dir, target_os, function(){	

					for (let target in engine.export_targets || []) {
						if (target_os == target) {
							let platforms = engine.export_targets[target]
							if (platforms === false)
								this_ref.doneToast(target_os);
							else {
								this_ref.toast.text = "Building app";
								setupBinary(platforms);
							}
						}
					}
				});
			})
			.catch(err => {
				this.errToast();
				return console.error(err)
			});
	}
}

document.addEventListener("openProject", function(e){
	app.removeSearchGroup("Exporter");
	app.addSearchKey({key: 'Export game', group:"Exporter", onSelect: function() {
		new Exporter(app);
	}});

	let eng_settings = {};
	(engine.export_settings || []).forEach(s => {
		for (let prop of s) {
			if (typeof(prop) == "object" && prop.default)
				eng_settings[s[0]] = prop.default;
		}
	});
	app.projSetting("export",Object.assign(DEFAULT_EXPORT_SETTINGS(), app.projSetting("export"), eng_settings))
});
