class Settings extends Editor {
	constructor (...args) {
		super(...args);

		this.setupDragbox();
		this.setTitle("Settings");
		this.removeHistory();

		this.container.width = 240;
		this.container.height = 224;

        this.el_settings = new BlankeForm([
			['IDE'],
            ['theme','select',{'choices':Object.keys(app.themes),'default':app.settings.theme}]
		],true);
		this.el_settings.onChange('theme',(value)=>{
			app.setTheme(value);
		})

		this.appendChild(this.el_settings.container);
	}
}

document.addEventListener('openProject',()=>{
	app.removeSearchGroup("Settings");
	app.addSearchKey({key: 'IDE/Project Settings', group:"Settings", onSelect: function() {
		new Settings(app);
	}});
});