class Settings extends Editor {
	constructor (...args) {
		super(...args);
        let this_ref = this;

		this.setupDragbox();
		this.setTitle("Settings");
		this.removeHistory();
		this.hideMenuButton();

		this.container.width = 300;
		this.container.height = 270;

		app.refreshThemeList();
        let paths = ['plugin','engine','themes'];
        let files = ['autocomplete'];
        this.el_settings = new BlankeForm([
			['IDE'],
            ['theme','select',{'choices':app.themes,'default':app.settings.theme}],
            ['Paths'],
            ...paths.map((path)=>[path,'directory',{default:app.settings[path+'_path']}]),
            ...files.map((path)=>[path,'file',{default:app.settings[path+'_path']}])
		],true);
		this.el_settings.onChange('theme',(value)=>{
			app.setTheme(value);
		});
        // add onChange event listener for paths
        paths.forEach((path)=>{
            this_ref.el_settings.onChange(path,(value)=>{
                try {
                    nwFS.statSync(value);
                } catch (e) {
                    return app.settings[path+'_path'];
                }
                app.settings[path+'_path'] = value;
                app.saveAppData();

                app.refreshThemeList();
            });
        });
        files.forEach((path)=>{
            this_ref.el_settings.onChange(path,(value)=>{
                try {
                    nwFS.statSync(value);
                } catch (e) {
                    return app.settings[path+'_path'];
                }
                app.settings[path+'_path'] = value;
                app.saveAppData();
            });
        });
		this.appendChild(this.el_settings.container);
	}
}

document.addEventListener('openProject',()=>{
	app.removeSearchGroup("Settings");
	app.addSearchKey({key: 'IDE/Project Settings', group:"Settings", onSelect: function() {
		new Settings(app);
	}});
});