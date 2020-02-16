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

		this.container.width = 384;
		this.container.height = 112;

		// diplay list of target platforms
		this.platforms = Object.keys(app.engine.export_targets || []);

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

	}

	// dir : target directory to write bundled files to 
	bundle (dir, target_os, cb_done) {
		if (app.engine.bundle)
			app.engine.bundle(dir, target_os, cb_done);
	}

	static openDistFolder(os) {
		let path = nwPATH.join(app.project_path,"dist",os);
		elec.remote.shell.openItem(path);
		elec.remote.clipboard.writeText(path);
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
		let os_dir = nwPATH.join(app.project_path,"dist",target_os);
		let temp_dir = os_dir;

		blanke.toast("Starting export for "+target_os);

		let setupBinary = (binary_list) => {
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
				if (app.engine.setupBinary)
					app.engine.setupBinary(os_dir, temp_dir, platform, platforms[platform], cb_done, cb_err);
			}
		}

		this.toast = blanke.toast('Removing old files',-1);
		this.toast.icon = 'dots-horizontal';
		this.toast.style = 'wait';

		process.noAsar = true;
		nwFS.emptyDir(os_dir, err => {
			if (err) {
				this.errToast();
				return console.error(err)
			}
			// move assets
			if (app.engine.export_assets !== false)
				nwFS.copySync(app.getAssetPath(), nwPATH.join(temp_dir, 'assets'));
			let e_assets = app.engine.extra_bundle_assets || {}
			let extra_assets = e_assets[target_os] || e_assets['.'] || [];
			for (let a of extra_assets) {
				a = a.replace('<project_path>',app.project_path).replace('<engine_path>',app.ideSetting('engine_path'));
				nwFS.copySync(a, app.cleanPath(nwPATH.join(temp_dir, a)).replace(app.ideSetting('engine_path')+'/',''));
			}

			if (app.engine.preBundle)
				app.engine.preBundle(temp_dir, target_os);
			// create js file		
			this.toast.text = `Bundling files`
			this.bundle(temp_dir, target_os, () => {	

				let platforms = app.engine.export_targets[target_os]
		
				if (platforms === false)
					this.doneToast(target_os);
				else {
					this.toast.text = "Building app";
					setupBinary(platforms === true ? [target_os] : platforms);
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

	let eng_settings = {};
	(app.engine.export_settings || []).forEach(s => {
		for (let prop of s) {
			if (typeof(prop) == "object" && prop.default)
				eng_settings[s[0]] = prop.default;
		}
	});
	console.log(app.projSetting('export'))
	app.projSetting("export",Object.assign(DEFAULT_EXPORT_SETTINGS(), eng_settings, app.projSetting("export")))
});
