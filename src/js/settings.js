let paths = ["plugin", "themes", "engine"]
let files = ["background_image"]
let engine_list = []
let was_open = false
let can_be_empty_path = {
  background_image: true,
}

const addSetting = (obj, k, default_v) => {

}

class Settings extends Editor {
  constructor(...args) {
    super(...args)
    if (DragBox.focus("Settings", true)) return

    this.setupDragbox()
    this.setTitle("Settings")
    this.removeHistory()
    this.hideMenuButton()

    this.container.width = 384
    this.container.height = 384

    app.refreshThemeList()
    let proj_set = app.projSetting()
    let app_set = app.ideSetting()

    let engine_settings = []
    let engine_set_keys = []
    if (app.engine.project_settings) {
      engine_settings = app.engine.project_settings.map(form_set => {
        let ret = JSON.parse(JSON.stringify(form_set))
        if (ret.length <= 2) ret[0] = "GAME > " + ret[0]
        else {
          engine_set_keys.push(ret[0])

          if (ret.length == 3 && ret[2].default != null)
            ret[2].default = proj_set[ret[0]]
        }
        return ret
      })
    }

    // setup default settings
    if (!app.projSetting("export")) app.projSetting("export", {})
    ifndef_obj(app.projSetting("export"), DEFAULT_EXPORT_SETTINGS())

    // combine engine settings for form
    let engine_export_settings = []
    let engine_export_keys = []
    if (app.engine.export_settings) {
      engine_export_settings = app.engine.export_settings.map(form_set => {
        let ret = JSON.parse(JSON.stringify(form_set))
        if (ret.length <= 2) ret[0] = "EXPORT > " + ret[0]
        else {
          ret[0] = "export." + ret[0]
          engine_export_keys.push(ret[0])
          if (ret.length == 3 && ret[2].default != null)
            ret[2].default = proj_set.export[ret[0].replace(/\w+\.(.*)/, "$1")]
        }
        return ret
      })
    }

    // set up the form options
    // prettier-ignore
    let form_options = [
      ["GAME"],
      //['first_scene','select',{'choices':Code.classes.scene,'default':proj_set.first_scene}],
      ["window_size", "number", { step: 1, min: 1, max: 7, default: proj_set.window_size }],
      ["game_size", "number", { step: 1, min: 1, max: 7, default: proj_set.game_size }],
      // ["engine", "select", { choices: engine_list, default: proj_set.engine }],
      ...engine_settings,
      ["EXPORT > GENERAL"],
      ["export.name", "text", { default: app.projSetting("export").name }],
      ...engine_export_settings,
      ["IDE", true]
      ["max_windows", "number", { min: 1, max: 5, default: app_set.max_windows }],
      ["theme", "select", { choices: app.themes, default: app_set.theme }],
      ["show_help_text", "checkbox", { default: app_set.show_help_text }],
      ["run_save_code", "checkbox", { default: app_set.run_save_code, label: "save code before runs" }],
      ["LICENSE", true],
      ["license_email", "text", { default: app_set.license_email }],
      ["license_key", "text", { default: app_set.license_key ? app.decrypt(app_set.license_key) : "" }],
      ["Paths", true],
      ...paths.map(path => [path, "directory", { default: app_set[path + "_path"] }]),
      ...files.map(path => [path, "file", { default: app_set[path + "_path"] }])
    ]
    this.el_settings = new BlankeForm(form_options, true);
    // prettier-ignore
    ["engine", "game_size", "window_size", ...engine_set_keys].forEach(s => {
      this.el_settings.onChange(s, v => {
        app.projSetting(s, v)
        app.saveSettings()
        if (s === "engine") {
          was_open = true
          this.close()
        }
      })
    });
    // prettier-ignore
    [
      "theme", "run_save_code", "max_windows", "show_help_text", "show_file_explorer",
      "license_email", "license_key"
    ].forEach(s => {
      this.el_settings.onChange(s, v => {
        if (s === "license_key")
          v = app.encrypt(v)

        app.ideSetting(s, v)
        app.saveAppData()

        if (s === "theme") app.setTheme(v)
      })
    })

    const export_keys = ["export.name", ...engine_export_keys]
    export_keys.forEach(s => {
      this.el_settings.onChange(s, val => {
        app.projSetting("export")[s.replace(/\w+\.(.*)/, "$1")] = val
        app.saveSettings()
      })
    })
    // add onChange event listener for paths
    paths.forEach(path => {
      this.el_settings.onChange(path, value => {
        try {
          nwFS.statSync(value)
        } catch (e) {
          return app.ideSetting(path + "_path")
        }
        app.ideSetting(path + "_path", app.cleanPath(value))

        app.refreshThemeList()
      })
    })
    files.forEach(path => {
      this.el_settings.onChange(path, value => {
        try {
          if (!can_be_empty_path[path]) nwFS.statSync(value)
        } catch (e) {
          return app.ideSetting(path + "_path")
        }
        app.ideSetting(
          path + "_path",
          can_be_empty_path[path] && value.length <= 1
            ? value
            : app.cleanPath(value)
        )

        if (path == "background_image")
          app.setBackgroundImage(app.cleanPath(value))
        app.saveAppData()
        if (path == "js_engine") app.watchJsEngine()
      })
    })
    this.appendChild(this.el_settings.container)
  }

  static addProjectSetting() {

  }
}

document.addEventListener("openProject", () => {
  app.removeSearchGroup("Settings")
  app.addSearchKey({
    key: "IDE/Project Settings",
    group: "Settings",
    onSelect: function () {
      new Settings()
    },
  })
})

document.addEventListener("engine_config_load", () => {
  if (was_open) {
    was_open = false
    new Settings()
  }
})

document.addEventListener("ideReady", e => {
  paths.forEach(p => {
    app.ideSetting(p + "_path", app.cleanPath(app.ideSetting(p + "_path")))
  })
  files.forEach(p => {
    app.ideSetting(p + "_path", app.cleanPath(app.ideSetting(p + "_path")))
  })
  app.saveAppData()
})
