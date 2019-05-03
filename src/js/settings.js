class Settings extends Editor {
	constructor (...args) {
		super(...args);

		this.setupDragbox();
		this.setTitle("Settings");
		this.removeHistory();

		this.container.width = 400;
		this.container.height = 350;

        this.el_settings = new BlankeForm([
            
        ]);
	}
}

document.addEventListener('openProject',()=>{
	app.removeSearchGroup("Settings");
	app.addSearchKey({key: 'IDE/Project Settings', group:"Settings", onSelect: function() {
		new Settings(app);
	}});
});