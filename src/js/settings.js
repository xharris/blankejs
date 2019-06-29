let paths = ['plugin','engine','themes'];
let files = ['autocomplete'];

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
        this.el_settings = new BlankeForm([
            ['GAME'],
            ['first_scene','select',{'choices':Code.classes.scene,'default':app.project_settings.first_scene}],
            ['game_size','number',{'inputs':2, 'separator':'x', 'step':1, 'main':1, 'default':app.project_settings.size}],
			['IDE'],
            ['theme','select',{'choices':app.themes,'default':app.settings.theme}],
            ['Paths'],
            ...paths.map((path)=>[path,'directory',{default:app.settings[path+'_path']}]),
            ...files.map((path)=>[path,'file',{default:app.settings[path+'_path']}])
        ],true);
        this.el_settings.onChange('first_scene',(value)=>{
            app.project_settings.first_scene = value;
            app.saveSettings();
        });
        this.el_settings.onChange('game_size',(value)=>{
            app.project_settings.size = value; 
            app.saveSettings();
        });
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
                app.settings[path+'_path'] = app.cleanPath(value);
                if (path == 'engine') 
                    Settings.watchEngine();
                if (path == 'autocomplete')
                    Settings.watchAutocomplete();
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
                app.settings[path+'_path'] = app.cleanPath(value);
                app.saveAppData();
            });
        });
		this.appendChild(this.el_settings.container);
    }
    
    static watchEngine () {
        app.minifyEngine();
        if (engine_watch)
            engine_watch.close();
        engine_watch = nwWATCH(app.settings.engine_path, {recursive: true}, (e, file) => {   
            app.minifyEngine();
        });
    }

    static watchAutocomplete () {
		if (autocomplete_watch) {
            autocomplete_watch.close();
            dispatchEvent("autocompleteChanged");
        }
	    autocomplete_watch = nwFS.watch(app.settings.autocomplete_path, function(e){
			dispatchEvent("autocompleteChanged");
			blanke.toast("autocomplete reloaded!");
		});
    }
}

document.addEventListener('openProject',()=>{
	app.removeSearchGroup("Settings");
	app.addSearchKey({key: 'IDE/Project Settings', group:"Settings", onSelect: function() {
		new Settings(app);
	}});
});

let engine_watch, autocomplete_watch;
document.addEventListener('ideReady',(e)=>{
    Settings.watchEngine();
    Settings.watchAutocomplete();

    paths.forEach(p => {app.settings[p+'_path'] = app.cleanPath(app.settings[p+'_path'])});
    files.forEach(p => {app.settings[p+'_path'] = app.cleanPath(app.settings[p+'_path'])});
    app.saveAppData();
})