let paths = ["plugin", "engine", "themes"];
let files = ["autocomplete", "js_engine", "background_image"];
let can_be_empty_path = {
  background_image: true,
};

class Settings extends Editor {
  constructor(...args) {
    super(...args);
    if (DragBox.focus("Settings")) return;

    this.setupDragbox();
    this.setTitle("Settings");
    this.removeHistory();
    this.hideMenuButton();

    this.container.width = 384;
    this.container.height = 384;

    app.refreshThemeList();
    let proj_set = app.projSetting();
    let app_set = app.ideSetting();

    let autoplay_settings = app.engine.game_preview_enabled
      ? [
          [
            "game_preview_enabled",
            "checkbox",
            {
              default: app_set.game_preview_enabled,
              label: "show preview of game while coding",
            },
          ],
          [
            "autoplay_preview",
            "checkbox",
            { default: proj_set.autoplay_preview },
          ],
          [
            "autoreload_external_run",
            "checkbox",
            {
              default: app_set.autoreload_external_run,
              label: "auto-reload external run",
              desc:
                "when a game is run using the Play button, it can be automatically refreshed when the code changes",
            },
          ],
        ]
      : [];

    let engine_settings = [];
    let engine_set_keys = [];
    if (app.engine.project_settings) {
      engine_settings = app.engine.project_settings.map(form_set => {
        let ret = JSON.parse(JSON.stringify(form_set));
        if (ret.length <= 2) ret[0] = "GAME > " + ret[0];
        else {
          engine_set_keys.push(ret[0]);
          if (ret.length == 3 && ret[2].default != null)
            ret[2].default = proj_set[ret[0]];
        }
        return ret;
      });
    }

    // setup default settings
    if (!app.projSetting("export")) app.projSetting("export", {});
    ifndef_obj(app.projSetting("export"), DEFAULT_EXPORT_SETTINGS());

    // combine engine settings for form
    let engine_export_settings = [];
    let engine_export_keys = [];
    if (app.engine.export_settings) {
      engine_export_settings = app.engine.export_settings.map(form_set => {
        let ret = JSON.parse(JSON.stringify(form_set));
        if (ret.length <= 2) ret[0] = "EXPORT > " + ret[0];
        else {
          ret[0] = "export." + ret[0];
          engine_export_keys.push(ret[0]);
          if (ret.length == 3 && ret[2].default != null)
            ret[2].default = proj_set.export[ret[0].replace(/\w+\.(.*)/, "$1")];
        }
        return ret;
      });
    }
    // set up the form options
    let form_options = [
      ["GAME"],
      //['first_scene','select',{'choices':Code.classes.scene,'default':proj_set.first_scene}],
      [
        "window_size",
        "number",
        { step: 1, min: 1, max: 7, default: proj_set.window_size },
      ],
      [
        "game_size",
        "number",
        { step: 1, min: 1, max: 7, default: proj_set.game_size },
      ],
      ...engine_settings,
      ["EXPORT > GENERAL"],
      ["export.name", "text", { default: app.projSetting("export").name }],
      ...engine_export_settings,
      ["IDE"],
      ...autoplay_settings,
      ["theme", "select", { choices: app.themes, default: app_set.theme }],
      [
        "quick_access_size",
        "number",
        { min: 1, default: app_set.quick_access_size },
      ],
      [
        "run_save_code",
        "checkbox",
        { default: app_set.run_save_code, label: "save code before runs" },
      ],
      ["Paths", true],
      ...paths.map(path => [
        path,
        "directory",
        { default: app_set[path + "_path"] },
      ]),
      ...files.map(path => [
        path,
        "file",
        { default: app_set[path + "_path"] },
      ]),
    ];
    this.el_settings = new BlankeForm(form_options, true);
    [
      "game_size",
      "window_size",
      "autoplay_preview",
      ...engine_set_keys,
    ].forEach(s => {
      this.el_settings.onChange(s, v => {
        app.projSetting(s, v);
        app.saveSettings();
      });
    });
    [
      "quick_access_size",
      "game_preview_enabled",
      "autoreload_external_run",
      "theme",
      "run_save_code",
    ].forEach(s => {
      this.el_settings.onChange(s, v => {
        app.ideSetting(s, v);
        app.saveAppData();

        if (s === "quick_access_size") app.refreshQuickAccess();
        if (s === "theme") app.setTheme(v);
      });
    });
    ["export.name", ...engine_export_keys].forEach(s => {
      this.el_settings.onChange(s, val => {
        app.projSetting("export")[s.replace(/\w+\.(.*)/, "$1")] = val;
      });
    });
    // add onChange event listener for paths
    paths.forEach(path => {
      this.el_settings.onChange(path, value => {
        try {
          nwFS.statSync(value);
        } catch (e) {
          return app.ideSetting(path + "_path");
        }
        app.ideSetting(path + "_path", app.cleanPath(value));
        if (path == "engine") Settings.watchEngine();

        app.refreshThemeList();
      });
    });
    files.forEach(path => {
      this.el_settings.onChange(path, value => {
        try {
          if (!can_be_empty_path[path]) nwFS.statSync(value);
        } catch (e) {
          return app.ideSetting(path + "_path");
        }
        app.ideSetting(
          path + "_path",
          can_be_empty_path[path] && value.length <= 1
            ? value
            : app.cleanPath(value)
        );

        if (path == "autocomplete") app.watchAutocomplete();
        if (path == "background_image")
          app.setBackgroundImage(app.cleanPath(value));
        app.saveAppData();
        if (path == "js_engine") app.watchJsEngine();
      });
    });
    this.appendChild(this.el_settings.container);
  }
}

document.addEventListener("openProject", () => {
  app.removeSearchGroup("Settings");
  app.addSearchKey({
    key: "IDE/Project Settings",
    group: "Settings",
    onSelect: function () {
      new Settings(app);
    },
  });
});

let engine_watch, autocomplete_watch;
document.addEventListener("ideReady", e => {
  app.watchJsEngine();
  app.watchAutocomplete();

  paths.forEach(p => {
    app.ideSetting(p + "_path", app.cleanPath(app.ideSetting(p + "_path")));
  });
  files.forEach(p => {
    app.ideSetting(p + "_path", app.cleanPath(app.ideSetting(p + "_path")));
  });
  app.saveAppData();
});
