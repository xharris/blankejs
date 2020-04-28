// const nwUGLY = require("uglify-es");

module.exports.settings = {
  game_preview_enabled: false,
  main_file: "main.js",
  file_ext: ["js"],
  language: "javascript",
  plugin_info_key: k => `\\*\\s*${k}\\s*:\\s*(.+)`,
  get script_path() {
    return nwPATH.join(app.project_path, "scripts");
  },
  get plugin_path() {
    return nwPATH.join(app.engine_path, 'plugins')
  },
  code_associations: [
    [/\bScene\s*\(\s*[\'\"](.+)[\'\"]/, "scene"],
    [/(\w+)\s+extends\s+Entity\s*/, "entity"],
  ],
  add_script_templates: {
    state: `State("<NAME>",{
			start: function() {
		
			},
			update: function(dt) {
				
			},
			end: function() {
		
			}
		});
		`,
    entity: `Entity({
			init () {
		
			}
			update (dt) {
		
			}
		})
		`,
  },
  entity_sprite_parse: (text, info, cb) => {
    // use the first frame
    let re_frame_size = /frame_size\s*:\s*\[\s*(\d+)\s*,\s*(\d+)\s*\]/;
    let re_offset = /offset\s*:\s*\[\s*(\d+)\s*,\s*(\d+)\s*\]/;
    let re_frame = /frames\s*:\s*(\d+)/;
    let re_spacing = /spacing\s*:\s*\[\s*(\d+)\s*,\s*(\d+)\s*\]/;
    let re_comment = /\/(?:\/|\*).*/;

    let match;
    if ((match = re_frame_size.exec(text.replace(re_comment, "")))) {
      info.cropped = true;
      info.frame_size = [parseInt(match[1]), parseInt(match[2])];
    } else {
      // get image size
      let img = new Image();
      img.onload = () => {
        info.frame_size = [img.width, img.height];
        cb(null, info);
      };
      img.src = "file://" + info.path;
    }
    if ((match = re_offset.exec(text.replace(re_comment, ""))))
      info.offset = [parseInt(match[1]), parseInt(match[2])];

    if ((match = re_frame.exec(text.replace(re_comment, ""))))
      info.frames = parseInt(match[1]);

    if ((match = re_spacing.exec(text.replace(re_comment, "")))) {
      info.offset[0] += parseInt(match[1]);
      info.offset[1] += parseInt(match[1]);
    }
    if (info.cropped) cb(info);
  },
  play: options => {
    let proj_set = app.projSetting();
    let game = new GamePreview(null, {
      ide_mode: false,
      scene: proj_set.first_scene,
      size: proj_set.size,
    });
    let writeTempHTML = cb => {
      nwFS.writeFile(
        nwPATH.join(app.project_path, "temp.html"),
        game.getSource(),
        cb
      );
    };
    writeTempHTML(() => {
      app.newWindow(
        nwPATH.join(app.project_path, "temp.html"),
        {
          width: proj_set.size[0],
          height: proj_set.size[1],
          useContentSize: true,
          resizable: app.projSetting("export").resizable,
          webPreferences: {
            nodeIntegration: true,
            webgl: true,
            webSecurity: false,
            experimentalFeatures: true,
            experimentalCanvasFeatures: true,
          },
        },
        win => {
          let src_watch;
          win.on("closed", function () {
            document.removeEventListener("codeSaved", reloadWindow);
            document.removeEventListener("engineChange", reloadWindow);
            nwFS.remove(nwPATH.join(app.project_path, "temp.html"));
            return true; //this.close(true);
          });
          let reloadWindow = () => {
            writeTempHTML(() => {
              try {
                win.reload();
              } catch (e) { }
            });
          };
          if (app.ideSetting("autoreload_external_run")) {
            document.addEventListener("codeSaved", reloadWindow);
            document.addEventListener("engineChange", reloadWindow);
          }

          /*
                    let menu_bar = new nw.Menu({type:'menubar'});
                    menu_bar.append(new nw.MenuItem({
                        label: 'Show dev tools',
                        click: () => { win.showDevTools(); }
                    }));
                    win.menu = menu_bar;
                    */
        }
      );
    });
  },
  minifyEngine: (cb_err, cb_done, opt) => {
    let code_obj = {};
    let walker = nwWALK.walk(app.ideSetting("engine_path"));
    let plugin_code = "";
    walker.on("file", (path, stat, next) => {
      // place all code in one object
      if (stat.isFile() && stat.name.endsWith(".js"))
        code_obj[stat.name] =
          nwFS.readFileSync(nwPATH.join(path, stat.name), "utf-8") + "\n\n";
      next();
    });
    walker.on("errors", () => {
      cb_err();
    });
    walker.on("end", () => {
      // get blanke.js classes
      GamePreview.engine_classes = re_engine_classes.exec(
        code_obj["blanke.js"]
      )[1];
      let other_classes = Plugins.getClassNames();
      if (other_classes.length > 0)
        GamePreview.engine_classes += ", " + other_classes.join(", ");
      // uglify
      let code = {
        error: false,
        code: Object.values(code_obj).join("\n"),
      };
      if (opt.wrapper) {
        code.code = opt.wrapper(code.code);
        code_obj.user_code = code.code;
      }

      if (opt.minify) {
        code = nwUGLY.minify(code_obj, {
          ie8: true,
          compress: opt.release ? {} : false,
          keep_classnames: true,
          mangle: { toplevel: false },
        });
      }
      if (!code.error) {
        if (opt.save_internal) app.engine_code = code.code;
        nwFS.writeFile("blanke.min.js", code.code, "utf-8");
        // all done
        cb_done(code.code);
      }
    });
  },
  export_targets: {
    windows: ["win32-x64"],
    mac: ["darwin-x64"],
    linux: ["linux-arm64"],
    web: false,
  },
  extra_bundle_assets: [
    "04B_03.ttf",
    "gamecontrollerdb.txt",
    "game.css",
    "config.json",
  ],
  preBundle: (dir, target_os) => {
    if (target_os != "web") {
      // entry.js
      nwFS.writeFileSync(
        nwPATH.join(dir, "entry.js"),
        `
const elec = require('electron');
//process.noAsar = true;
elec.app.on('ready', function(){
	let main_window = new elec.BrowserWindow({
		width: ${app.projSetting("size")[0]},
		height: ${app.projSetting("size")[1]},
		frame: ${!app.projSetting("export").frameless},
		resizable: ${app.projSetting("export").resizable}
	})
	if (main_window.setMenuBarVisibility)
		main_window.setMenuBarVisibility(false);
	main_window.loadFile('index.html');
});
elec.app.commandLine.appendSwitch('ignore-gpu-blacklist');
`,
        "utf-8"
      );
      // package.json
      nwFS.writeFileSync(
        nwPATH.join(dir, "package.json"),
        `
{
	"name": "${app.projSetting("export").name}",
	"description": "Made with BlankE",
	"version": "1.0",
	"main": "./entry.js",
	"chromium-args": "--enable-webgl --ignore-gpu-blacklist"
}
`,
        "utf-8"
      );
    }
  },
  bundle: (dir, target_os, cb_done) => {
    let js_path = nwPATH.join(dir, app.projSetting("export").name + ".js");

    let game = new GamePreview();
    let scripts = GamePreview.getScriptOrder();
    let user_code = "";
    for (let path of scripts) {
      user_code += nwFS.readFileSync(path, "utf-8") + "\n";
    }
    // get copy of other engine settings
    let new_config = JSON.parse(JSON.stringify(app.projSetting()));
    for (let k in new_config.export) {
      new_config[k] = new_config.export[k];
    }

    app.minifyEngine(
      code => {
        nwFS.writeFileSync(js_path, code, "utf-8");
        let str_html = GamePreview.getHTML(
          `<body>
<div id="game"></div>
</body>
<script>
var game_instance;
window.addEventListener('load',()=>{
	game_instance = Blanke.run('#game','${app.projSetting("export").name}');
})
</script>`,
          false,
          nwPATH.basename(js_path)
        );

        nwFS.writeFileSync(nwPATH.join(dir, "index.html"), str_html, "utf-8");
        cb_done();
      },
      {
        silent: true,
        release: true,
        minify: app.projSetting("export").minify, // true,
        wrapper: code => `
${code}
Blanke.addGame('${app.projSetting("export").name}',{
	config: ${JSON.stringify(new_config)},
	width: ${app.projSetting("size")[0]},
	height: ${app.projSetting("size")[1]},
	assets: [${game.getAssetStr()}],
	onLoad: function(classes){
		let { ${GamePreview.engine_classes} } = classes;
		let TestScene = () => {};
		${user_code}
	}
});
`,
      }
    );
    app.projSetting("os", target_os); // why ?
  },
  setupBinary: (os_dir, temp_dir, platform, arch, cb_done, cb_err) => {
    /*
    let packager = require("electron-packager");
    packager({
      dir: temp_dir,
      out: os_dir,
      platform: platform,
      arch: arch,
      overwrite: true,
      icon: "src/logo",
    })
      .then(err => {
        cb_done();
      })
      .catch(err => {
        cb_err(err);
      });
      */
  },
};
