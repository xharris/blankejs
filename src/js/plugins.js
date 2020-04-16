let plugin_info = {};

let pathJoin;
let plugin_watch;

// get a list of .lua and .js files
function refreshPluginList(silent) {
  blanke.cooldownFn("refreshPlugin", 500, function () {
    inspectPlugins(silent);
  });
}

// scan and copy plugins
let temp_plugin_info = {};
function inspectPlugins(silent) {
  const plugin_path = app.relativePath(app.ideSetting("plugin_path"));

  function inspectFile(file) {
    file = app.cleanPath(file);
    let info_key = app
      .cleanPath(nwPATH.relative(plugin_path, nwPATH.dirname(file)))
      .replace(/\/.*/g, "");
    let info_keys = ["Name", "Author", "Description", "ID", "Enabled"];

    if (!temp_plugin_info[info_key]) {
      temp_plugin_info[info_key] = {
        files: [],
        docs: [],
        enabled: true,
        module: null,
        id: "",
        classes: [],
      };
    }

    if (nwPATH.basename(file) == "index.js") {
      // it's a module
      let module = temp_plugin_info[info_key].module;
      let module_path = file;
      if (!nwPATH.isAbsolute(file))
        module_path = nwPATH.join(nwPATH.relative(plugin_path, ""), file);
      module_path = require.resolve(module_path);

      if (module) {
        if (module.onPluginUnload) module.onPluginUnload();
        delete require.cache[module_path];
      }

      temp_plugin_info[info_key].module = require(module_path);
      if (temp_plugin_info[info_key].module.onPluginLoad)
        temp_plugin_info[info_key].module.onPluginLoad();

      module = temp_plugin_info[info_key].module;
      if (module.info) {
        for (let k of info_keys) {
          if (k == "Enabled")
            temp_plugin_info[info_key].enabled = module.info.enabled;
          else
            temp_plugin_info[info_key][k.toLowerCase()] =
              module.info[k.toLowerCase()];
        }
        if (Array.isArray(module.info.classes))
          temp_plugin_info[info_key].classes = module.info.classes;
      }
      return;
    }

    if (
      app.engine.file_ext &&
      app.engine.file_ext.some(f => file.endsWith(f))
    ) {
      let data = nwFS.readFileSync(file, "utf-8");

      // add file path
      if (!temp_plugin_info[info_key].files.includes(file))
        temp_plugin_info[info_key].files.push(file);

      for (let k of info_keys) {
        let re = new RegExp(app.engine.plugin_info_key(k));
        //plugin_info
        let match = re.exec(data);
        if (match) {
          if (k == "Enabled")
            temp_plugin_info[info_key].enabled = match[1].trim();
          else temp_plugin_info[info_key][k.toLowerCase()] = match[1].trim();
        }
      }
      if (!temp_plugin_info[info_key].name)
        temp_plugin_info[info_key].name = nwPATH.basename(file);
    }
    if (
      file.endsWith(".md") &&
      !["license.md"].includes(nwPATH.basename(file).toLowerCase())
    ) {
      temp_plugin_info[info_key].docs.push(file);
    }
  }

  function inspectFolder(folder) {
    let walker = nwWALK.walk(folder);
    walker.on("file", (path, stats, next) => {
      if (stats.isFile()) inspectFile(pathJoin(path, stats.name));
      else inspectFolder(pathJoin(path, stats.name));
      next();
    });
    walker.on("end", () => {
      Plugins.refreshList();
    });
  }

  nwFS.ensureDir(plugin_path, err => {
    if (err) return console.error(err);

    nwFS.readdir(plugin_path, (err, files) => {
      if (err) return;

      Plugins.clearPlugins();
      for (let f of files) {
        let full_path = pathJoin(plugin_path, f);
        // .js
        if (app.engine.file_ext.some(_f => f.endsWith(_f))) {
          inspectFile(full_path);
          //nwFS.copyFileSync(pathJoin(plugin_path,f), pathJoin(eng_plugin_dir,f));
        }

        // .zip/.rar/.blex
        if (f.endsWith(".blex") || f.endsWith(".zip") || f.endsWith(".rar")) {
          let dir_path = pathJoin(plugin_path, f.split(".")[0]);
          if (!nwFS.statSync(dir_path).isDirectory())
            nwZIP2(full_path).extractAllTo(dir_path, true);
          inspectFolder(dir_path);
        }

        // dir
        if (nwFS.statSync(full_path).isDirectory()) {
          d = nwPATH.basename(f);
          //nwFS.copySync(pathJoin(plugin_path,d), pathJoin(eng_plugin_dir,d))
          inspectFolder(pathJoin(plugin_path, d));
        }

        // if (!silent) blanke.toast("Plugins loaded!")
      }

      Plugins.refreshList();

      app.sanitizeURLs();
      dispatchEvent("loadedPlugins");
    });
  });

  // add .js files to ide somehow
  // ...
}

let plugin_window;
class Plugins extends Editor {
  constructor(...args) {
    super(...args);
    if (DragBox.focus("Plugins")) return;

    this.setupDragbox();
    this.setTitle("Plugins");
    this.removeHistory();
    this.hideMenuButton();

    this.container.width = 400;
    this.container.height = 370;

    plugin_window = this;

    this.el_list_container = app.createElement("div", "list-container");
    this.appendChild(this.el_list_container);

    this.el_reference = {};
    Plugins.refreshList();
  }

  static refreshList() {
    // check which plugins are valid
    for (let key in temp_plugin_info) {
      let info = temp_plugin_info[key];
      if (info.id) {
        if (info.enabled !== false) {
          plugin_info[info.id] = info;
        } else {
          // disabled and remove docs
          for (let file of info.docs) {
            Docview.removePlugin(file);
          }
        }
      }
    }

    // enable docs
    for (let key in plugin_info) {
      let p_info = plugin_info[key];

      if (p_info.docs.length > 0) {
        let file = p_info.docs[0]; // only allow first doc file for now
        let doc_info = {
          name: p_info["name"] || nwPATH.basename(file),
          author: null,
        };

        let data = nwFS.readFileSync(file, "utf-8");
        let info_keys = ["Name", "Author"];
        // get info about plugrin from readme
        for (let k of info_keys) {
          let re = new RegExp(
            `\\[\\/\\/\\]: # \\(${k}:\\s*([\\w\\s\\.]+)\\s*\\)`
          );
          let match = re.exec(data);
          if (match) doc_info[k.toLowerCase()] = match[1].trim();
        }

        let getInfo = k => (doc_info[k] != null ? doc_info[k] : p_info[k]);
        if (getInfo("enabled"))
          Docview.addPlugin(
            getInfo("name") +
              (getInfo("author") ? " (" + getInfo("author") + ")" : ""),
            file
          );
        else Docview.removePlugin(file);
      }
    }

    // copy files if the plugin is already enabled
    if (app.projSetting("enabled_plugins")) {
      for (let id in plugin_info) {
        if (app.projSetting("enabled_plugins")[id] == true) {
          Plugins.enable(id);
        } else {
          Plugins.disable(id);
        }
      }
    }

    if (!plugin_window) return;

    for (let key in plugin_info) {
      // create the list item elements
      if (!plugin_window.el_reference[key]) {
        let el_ref = {};
        el_ref.el_toggle = app.createElement("label", ["toggle", "form-group"]);
        el_ref.el_toggle.dataset.type = "checkbox";
        el_ref.el_toggle.key_ref = key;
        el_ref.el_container = app.createElement("div", ["container", "dark"]);
        el_ref.el_container.appendChild(el_ref.el_toggle);

        plugin_window.el_list_container.appendChild(el_ref.el_container);
        plugin_window.el_reference[key] = el_ref;
      }
    }
    // remove el references that are no longer a plugin
    for (let key in plugin_window.el_reference) {
      let exists = true;
      if (!plugin_info[key] || plugin_info[key].enabled == false)
        exists = false;
      else {
        for (let f of plugin_info[key].files) {
          if (!nwFS.pathExistsSync(f)) exists = false;
        }
      }
      if (!exists) {
        Plugins.disable(key);
        for (let doc of plugin_info[key].docs) {
          Docview.removePlugin(doc);
        }
        plugin_window.el_reference[key].el_container.remove();
        delete plugin_window.el_reference[key];
      }
    }
    // edit values of plugin elements
    for (let key in plugin_window.el_reference) {
      let el_ref = plugin_window.el_reference[key];
      let info = plugin_info[key];
      el_ref.el_toggle.innerHTML = `
				<div class='form-inputs'>
					<input type='checkbox' class='form-checkbox' ${
            app.projSetting("enabled_plugins")[info.id] == true ? "checked" : ""
          }/>
					<span class='checkmark'></span>
				</div>
				<div class='form-label'>
					<div class='name'>${info.name}</div>
					${info.author ? `<div class='author'>${info.author} (${info.id})</div>` : ""}
					${info.description ? `<div class='description'>${info.description}</div>` : ""}
				</label>
			`;
      el_ref.el_toggle
        .querySelector(".form-checkbox")
        .addEventListener("change", e => {
          let key_ref = el_ref.el_toggle.key_ref;
          plugin_info[key_ref].enabled = e.target.checked;
          if (e.target.checked) Plugins.enable(key_ref);
          else Plugins.disable(key_ref);
        });
    }
    // already enabled plugins
    for (let key in app.projSetting("enabled_plugins")) {
      if (app.projSetting("enabled_plugins")[key] == true) {
        Plugins.enable(key);
      } else Plugins.disable(key);
    }
  }

  static getAutocomplete = () => {
    let ret = {};
    for (let p in plugin_info) {
      let info = plugin_info[p];
      if (info.module && info.enabled && info.module.autocomplete)
        ret[p] = info.module.autocomplete;
    }
    return ret;
  };

  static enable(key) {
    const plugin_path = app.relativePath(app.ideSetting("plugin_path"));
    const engine_path = app.engine_path;

    nwFS.ensureDir(pathJoin(engine_path, "plugins"));

    if (plugin_info[key]) {
      for (let path of plugin_info[key].files) {
        let rel_path = nwPATH
          .relative(plugin_path, path)
          .replace(/^(.+?)[\\\/]/, "");
        nwFS.copySync(path, pathJoin(engine_path, "plugins", key, rel_path));
      }
      app.projSetting("enabled_plugins")[key] = true;
      dispatchEvent("pluginChanged", { key: key, info: plugin_info[key] });
      app.saveSettings();
    }
  }

  static disable(key) {
    const engine_path = app.engine_path;

    if (!plugin_info[key]) return;
    // remove file
    /*for (let path of plugin_info[key].files) {
			
      nwFS.removeSync(
        pathJoin(engine_path, "plugins", key, nwPATH.basename(path))
			);
    }*/
    nwFS.removeSync(pathJoin(engine_path, "plugins", key));
    app.projSetting("enabled_plugins")[key] = false;
    dispatchEvent("pluginChanged", { key: key, info: plugin_info[key] });
    app.saveSettings();
  }

  static getClassNames() {
    let classnames = [];
    for (let p in plugin_info) {
      let info = plugin_info[p];
      if (info.enabled) classnames = classnames.concat(info.classes);
    }
    return classnames;
  }

  static clearPlugins() {
    const engine_path = app.engine_path;
    nwFS.emptyDirSync(pathJoin(engine_path, "plugins"));
  }
}

document.addEventListener("openProject", function (e) {
  if (!app.projSetting("enabled_plugins"))
    app.projSetting("enabled_plugins", {});
  app.saveSettings();
  refreshPluginList(true);
});

document.addEventListener("closeProject", function (e) {
  Plugins.clearPlugins();
});

document.addEventListener("ideReady", function (e) {
  pathJoin = nwPATH.join;
  app.addSearchKey({
    key: "Enable/disable plugins",
    onSelect: () => {
      new Plugins();
    },
  });
});

document.addEventListener("appdataSave", e => {
  const plugin_path = app.relativePath(app.ideSetting("plugin_path"));

  // watch for updates to plugins
  nwFS.ensureDir(plugin_path, err => {
    if (plugin_watch) plugin_watch.close();
    plugin_watch = app.watch(plugin_path, (evt_type, file) => {
      refreshPluginList();
    });
  });
});
