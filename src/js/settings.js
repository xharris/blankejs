let paths = ['plugin','engine','themes'];
let files = ['autocomplete'];

class Settings extends Editor {
	constructor (...args) {
		super(...args);
		if (DragBox.focus("Settings")) return;
        let this_ref = this;

		this.setupDragbox();
		this.setTitle("Settings");
		this.removeHistory();
		this.hideMenuButton();

		this.container.width = 300;
        this.container.height = 270;
        
		app.refreshThemeList();
        let proj_set = app.project_settings;
        let app_set = app.settings;

        let autoplay_settings;
        if (engine.game_preview_enabled) {
            autoplay_settings = [
                ['game_preview_enabled','checkbox',{'default':app_set.game_preview_enabled,'label':'show preview of game while coding'}]),
                ['autoplay_preview','checkbox',{'default':proj_set.autoplay_preview}]
            ];
        }
        this.el_settings = new BlankeForm([
            ['GAME'],
            ['first_scene','select',{'choices':Code.classes.scene,'default':proj_set.first_scene}],
            ['size','number',{'inputs':2, 'separator':'x', 'step':1, 'min':1, 'default':proj_set.size}],
            ['IDE'],
            ...autoplay_settings,
            ['theme','select',{'choices':app.themes,'default':app_set.theme}],
            ['quick_access_size','number',{'min':1,'default':app_set.quick_access_size}],
            ['autoreload_external_run','checkbox',{'default':app_set.autoreload_external_run,'label':'auto-reload external run','desc':'when a game is run using the Play button, it can be automatically refreshed when the code changes'}],
            ['Paths'],
            ...paths.map((path)=>[path,'directory',{default:app_set[path+'_path']}]),
            ...files.map((path)=>[path,'file',{default:app_set[path+'_path']}])
        ],true);
        //console.log(JSON.parse(JSON.stringify(app.project_settings)))
        ['first_scene','game_size','autoplay_preview'].forEach(s => {
            this.el_settings.onChange(s, v => {
                app.project_settings[s] = v;
                app.saveSettings();
            });
        });
        ['quick_access_size','game_preview_enabled','autoreload_external_run','theme'].forEach(s => {
            this.el_settings.onChange(s, v => {
                app.settings[s] = v;
                app.saveAppData();

                if (s === 'quick_access_size')
                    app.refreshQuickAccess();
                if (s === 'theme')
                    app.setTheme(v);
            });
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
                    app.watchAutocomplete();
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
        app.minifyEngine(null,{ save_internal: true });
        if (engine_watch)
            engine_watch.close();
        engine_watch = app.watch(app.settings.engine_path, (e, file) => {   
            app.minifyEngine(null,{ save_internal: true });
        });
    }

    static watchAutocomplete () {
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
    app.watchAutocomplete();

    paths.forEach(p => {app.settings[p+'_path'] = app.cleanPath(app.settings[p+'_path'])});
    files.forEach(p => {app.settings[p+'_path'] = app.cleanPath(app.settings[p+'_path'])});
    app.saveAppData();
})