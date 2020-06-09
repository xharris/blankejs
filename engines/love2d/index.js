// TODO: copy web_preload_image to relative path

const klaw = require('klaw')
const zlib = require('zlib')
const luamin = require('luamin')

const { spawn } = require("child_process");
const nwZIP = require("archiver"); // used for zipping

const isSymlink = unix_perms => (unix_perms & 0170000) === 0120000

const re_sprite_props = /(\w+)[=\{\s'"]+([\w\-\.\s]+)[\}\s'",]+?/g;
const binary_prefix = 'https://github.com/xharris/blankejs-lovefiles/raw/master'

const requireConf = (is_exporting) => {
  const type = app.projSetting("engine_type") || "oop";
  switch (type) {
    case "oop":
      return `
love.filesystem.setRequirePath( "?.lua;?/init.lua;lua/?.lua;lua/?/init.lua" )
require("blanke")
      `;

    case "ecs":
      return `
package.path = "lua/?.lua;lua/?/init.lua;" .. package.path
require("${is_exporting ? "lua.ecs" : "ecs"}")
Game.options.auto_require = false
      `;
  }
};
/*
package.path = "lua/?.lua;lua/?/init.lua;" .. package.path

BASEDIR = love.filesystem.getRealDirectory("lua"):match("(.-)[^%.]+$")
BASEDIR = string.sub(BASEDIR, 1, string.len(BASEDIR)-1)
local myPath = BASEDIR..'/lua/?.lua;'..BASEDIR..'/data/?.lua'
local myPath2 = 'lua/?.lua;/data/?.lua'

package.path = myPath
love.filesystem.setRequirePath( myPath2 )
*/
const generalConf = () => `
    t.identity = "${app.exportSetting("company_name") || "blanke"}.${app.exportSetting("name") || "game"}"
    t.window.title = "${app.exportSetting("name")}"
    -- t.gammacorrect = nil
`;

const runConf = () => {
  if (app.projSetting("write_conf")) {
    let p_level = app.projSetting("profiling_level")
    nwFS.writeFileSync(
      nwPATH.join(app.getAssetPath("scripts"), "conf.lua"),
      `io.stdout:setvbuf('no')
${p_level > 0 ? `do_profiling = ${p_level}` : ""}
${requireConf()}
function love.conf(t)
    t.console = true
    ${generalConf()}
end
`
    );
  }
};

const exportConf = os => {
  let resolution = getGameSize(os);
  return app.projSetting("write_conf")
    ? `
${requireConf(true)}
${os == "web" ? 'Window.os = "web"' : ""}
function love.conf(t)
    ${
    os == "web"
      ? `
    t.window.width = ${resolution[0]}
    t.window.height = ${resolution[1]}`
      : `
    ${generalConf()}
    `
    }
end
`
    : "";
};

const getGameSize = os => {
  if (os == "web" && app.projSetting("export")["override_game_size"])
    return app.projSetting("export").web_game_size;
  let res = app.projSetting("game_size");
  let aspect_ratio = [4, 3];
  let res_list = [512, 640, 800, 1024, 1280, 1366, 1920]; // indexing starts
  return [
    res_list[Math.max(0, res - 1)],
    (res_list[Math.max(0, res - 1)] / aspect_ratio[0]) * aspect_ratio[1],
  ];
};

const checkOS = target_os => {
  if (app.projSetting("export").os != target_os) {
    app.projSetting("export").os = target_os;
    app.saveSettings();
  }
};

module.exports.settings = {
  game_preview_enabled: false,
  main_file: "main.lua",
  file_ext: ["lua"],
  language: "lua",
  project_settings: [
    ["write_conf", "checkbox", { default: true, label: "auto-generate conf.lua" }],
    ["profiling_level", "number", { default: 0, step: 1, min: 0 }],
    ["engine_type", "select", { choices: ["oop", "ecs"], default: "oop" }],
  ],
  export_settings: [
    ["company_name", "text", {}],
    ["window/rendering"],
    ["filter", "select", { choices: ["linear", "nearest"], default: "linear" }],
    ["round_pixels", "checkbox", { defalt: false }],
    ...["frameless", "scale", "resizable", "fullscreen"].map(o => [
      o,
      "checkbox",
      { default: o === "scale" },
    ]),
    ["vsync", "select", { choices: ["on", "off", "adaptive"], default: "on" }],
    ["web"],
    ["web_autoplay", "checkbox", { label: "autoplay", defalt: false }],
    ["web_memory", "number", { label: "memory size", default: 24 }],
    ["web_stack", "number", { label: "stack size", default: 2 }],
    ["override_game_size", "checkbox", { default: false, title: "if enabled, web container will be the size given below" }],
    ["web_game_size", "number", { label: "canvas size", inputs: 2, default: [800, 600] }],
    ["web_preload_image", "text", { label: "preload image background (url)" }]
  ],
  get script_path() {
    return app.project_path;
  },
  get plugin_path() {
    const engine_type = app.projSetting("engine_type") || "oop"
    return nwPATH.join(app.engine_path, 'lua', engine_type === "oop" ? '' : 'ecs', 'plugins')
  },
  plugin_info_key: k => `--\s*${k}\s*:\s*(.+)`,
  code_associations: [
    [/\bEntity\s*\(\s*[\'\"](\w+)[\'\"],\s*/g, "entity"],
    [/State\(\"(\w+)\"/g, "state"],
  ],
  fn_trigger: ":",
  add_script_templates: {
    script: ``,
  },
  sprite_parse: (match, info, cb) => {
    // console.log('sprite',match,info)
    let img = new Image();
    img.onload = () => {
      info.frame_size = [img.width, img.height];

      // console.log(match)

      let props = match.splice(-1, 1);
      let new_match;
      let offx = 0,
        offy = 0,
        rows = 1,
        cols = 1,
        frame = 0,
        name;
      while ((new_match = re_sprite_props.exec(props))) {
        switch (new_match[1]) {
          case "cols":
            cols = parseInt(new_match[2]);
            break;
          case "rows":
            rows = parseInt(new_match[2]);
            break;
          case "frames":
            frame = parseInt(new_match[2].split("-")[0]);
            break;
          case "offx":
            offx = parseInt(new_match[2]);
            break;
          case "offy":
            offy = parseInt(new_match[2]);
            break;
        }
      }

      info.offset = [offx, offy];
      info.frame_size = [
        img.width / Math.max(cols, 0),
        img.height / Math.max(rows, 0),
      ];

      cb(info);
    };
    // info.name = name || nwPATH.basename(info.path).split('.').slice(0,-1).join('.');

    if (app.findAssetType(info.path) === "image")
      img.src = "file://" + info.path;
    else cb(info);
  },
  play: options => {
    // checkOS('ide');
    runConf();
    let eng_path = "love"; // linux, mac?
    if (app.os == "windows")
      eng_path = nwPATH.join(app.engine_dist_path(), "lovec");

    // create symlink to love/lua dir
    nwFS.removeSync(nwPATH.join(app.project_path, "lua"));
    nwFS.symlinkSync(
      nwPATH.join(app.engine_path, "lua"),
      nwPATH.join(app.project_path, "lua"),
      'junction'
    );

    let child = spawn(eng_path, ["."], { cwd: app.getAssetPath("scripts") });
    let con = new Console(true);
    child.stdout.on("data", data => {
      data = data
        .toString()
        .replace(/Could not open device.\s*/, "")
        .trim();
      data.split(/[\r\n]+/).forEach(l => con.log(l));
    });
    child.stderr.on("data", data => {
      app.error(data);
    });
    child.on("close", () => {
      nwFS.removeSync(nwPATH.join(app.project_path, "love2d"));
      con.tryClose();
    });
  },
  get export_targets() {
    const targets = {
      love: false,
      win32: true,
      win64: true,
      web: true
    }
    if (app.os === "mac")
      targets.mac64 = true
    if (app.os === "linux") {
      targets.linux_AppImage32 = true
      targets.linux_AppImage64 = true
    }
    return targets
  },
  export_assets: false,
  bundle: (dir, target_os, cb_done) => {
    let love_path = nwPATH.join(dir, app.projSetting("export").name + ".love");

    // conf.lua
    const str_conf = exportConf(target_os)

    const output = nwFS.createWriteStream(love_path)
    output.on("close", cb_done)
    const archive = nwZIP("zip", { zlib: { level: zlib.constants.Z_BEST_COMPRESSION } })
    archive.pipe(output)

    const minifyLua = path => nwFS.readFile(path, 'utf8')
      .then(data => path.endsWith(".lua") && target_os != "love" ?
        luamin.minify(data) : data
      )

    const filter = (path, ignores) => {
      path = app.cleanPath(path)
      return (path.length > 0 && ignores.some(i => path.match(i))) || (str_conf && path.match(/conf\.lua/))
    }

    // remove symlink
    nwFS.remove(nwPATH.join(app.project_path, "lua"))
      .then(() => new Promise((res, rej) => {
        if (str_conf) archive.append(luamin.minify(str_conf), { name: "conf.lua" })

        const ignores = [/^dist[\/\\]?/]
        const promises = []

        // project files
        klaw(app.project_path, {
          filter: item => !filter(nwPATH.relative(app.project_path, item), ignores)
        })
          .on('data', item => {
            const path = nwPATH.relative(app.project_path, item.path)

            // minify .lua?
            if (path.length > 0) {
              if (!item.stats.isDirectory() && path.endsWith(".lua"))
                promises.push(minifyLua(item.path).then(code => archive.append(code, { name: path })))
              else
                archive.file(item.path, { name: path })
            }
          })
          .on('end', () => res(promises))

      }))
      .then(promises => Promise.all(promises))
      .then(() => new Promise((res, rej) => {
        const ignores = []
        const promises = []

        const eng_type = app.projSetting("engine_type") || "oop";
        if (eng_type === "oop") ignores.push(/^ecs[\/\\]?/)
        if (eng_type === "ecs") ignores.push(/^blanke[\/\\]?/)
        const eng_path = nwPATH.join(app.engine_path, 'lua')

        klaw(eng_path, {
          filter: item => !filter(nwPATH.relative(eng_path, item), ignores)
        })
          .on('data', item => {
            const path = nwPATH.relative(eng_path, item.path)

            // minify .lua?
            if (path.length > 0) {
              if (!item.stats.isDirectory() && path.endsWith(".lua"))
                promises.push(minifyLua(item.path).then(code => archive.append(code, { name: path })))
              else
                archive.file(item.path, { name: path })
            }
          })
          .on('end', () => res(promises))
      }))
      .then(promises => Promise.all(promises))
      .then(() => archive.finalize())
  },
  binaries: {
    'windows-32': `${binary_prefix}/love-11.3-win32.zip`,
    'windows-64': `${binary_prefix}/love-11.3-win64.zip`,
    'linux-32': `${binary_prefix}/love-11.3-i686.AppImage`,
    'linux-64': `${binary_prefix}/love-11.3-x86_64.AppImage`,
    'mac-64': `${binary_prefix}/love-11.3-macos.zip`,
    'web-32': `${binary_prefix}/love.js`
  },
  binary_ext: {
    'linux': 'AppImage',
    'web': 'js'
  },
  exe_ext: {
    'windows': 'exe',
    'linux': 'AppImage',
    'mac': 'app',
    'web': 'js'
  },
  extra_bundle_assets: {
    win32: [
      "love.dll",
      "lua51.dll",
      "mpg123.dll",
      "msvcp120.dll",
      "msvcr120.dll",
      "OpenAL32.dll",
      "SDL2.dll",
      "license.txt",
    ].map(p => "<dist_path>/" + p),
    win64: [
      "love.dll",
      "lua51.dll",
      "mpg123.dll",
      "msvcp120.dll",
      "msvcr120.dll",
      "OpenAL32.dll",
      "SDL2.dll",
      "license.txt",
    ].map(p => "<dist_path>/" + p),
    web: ["<engine_path>/favicon.ico"],
  },
  cleanExport: (os_dir) => {
    nwFS.remove()
  },
  setupBinary: (os_dir, temp_dir, platform, arch, cb_done, cb_err) => {
    let export_settings = app.projSetting("export")
    let love_path = nwPATH.join(temp_dir, export_settings.name + ".love")
    let engine_path = app.engine_dist_path(platform, arch)
    let project_name = export_settings.name || "game"

    let resolution = getGameSize(platform);

    const cleanLove = () => nwFS.remove(love_path)

    if (platform == "windows") {
      let exe_path = nwPATH.join(os_dir, project_name + ".exe");
      // TODO: test on mac/linux
      // copy /b love.exe+game.love game.exe
      let f_loveexe = nwFS.createReadStream(
        nwPATH.join(engine_path, "love.exe"),
        { flags: "r", encoding: "binary" }
      );
      let f_gamelove = nwFS.createReadStream(love_path, {
        flags: "r",
        encoding: "binary",
      });
      let f_gameexe = nwFS.createWriteStream(exe_path, {
        flags: "w",
        encoding: "binary",
      });
      // set up callbacks
      f_loveexe.on("end", () => {
        f_gamelove.pipe(f_gameexe);
        // finished all merging
        nwFS.remove(love_path, () => {
          cb_done();
        });
      });
      // start merging
      f_loveexe.pipe(f_gameexe, { end: false });
    }

    if (platform == "mac") {
      const app_path = nwPATH.join(app.engine_path, "love-11.3-macos.zip")
      const out_path = nwPATH.join(os_dir, project_name + ".zip")
      const new_love_name = `${project_name}.love`
      const new_root = `${project_name}.app`

      const icon_path = nwPATH.join(app.engine_path, "logo.icns")
      const add_files = {
        [love_path]: `${new_root}/Contents/Resources/${new_love_name}`,
        [icon_path]: [
          `${new_root}/Contents/Resources/OS X AppIcon.icns`,
          `${new_root}/Contents/Resources/GameIcon.icns`
        ]
      }

      const replacements = {
        "$COMPANY_NAME": app.exportSetting("company_name") || "blanke",
        "$PROJECT_NAME": project_name
      }

      // copy .app zip
      // nwFS.copy(app_path, out_path)
      /*
      .then(() => nwFS.readFile(out_path))
      .then(zip_data => nwZIP().loadAsync(zip_data))
      .then(zip => zip.file("love.app/Contents/Info.plist")
          .then(data => {
            console.log(data)
          })
      )
      */

      const JSZip = require('jszip')

      const del_list = []
      const f_info = {}

      nwFS.readFile(app_path)
        .then(JSZip.loadAsync)

        // move all files from love.app to project_name.app
        .then(zip => {
          const checkFolder = f_obj => f_obj.forEach((_, f_obj) => {
            const file = f_obj.name

            if (f_obj.dir) {
              del_list.push(file)
              return checkFolder(zip.folder(file))
            } else {
              f_info[file] = {
                new_path: new_root + file.substring(file.indexOf('/')),
                options: {
                  comment: f_obj.comment,
                  date: f_obj.date,
                  dir: f_obj.dir,
                  unixPermissions: f_obj.unixPermissions,
                  dosPermissions: f_obj.dosPermissions
                },
              }
            }
          })
          checkFolder(zip.folder('love.app/'))

          return Promise.all(Object.keys(f_info).map(f => zip.file(f).async('nodebuffer').then(data => {
            f_info[f].content = data
          }))).then(() => zip)
        })

        .then(zip => {
          console.log(f_info)
          // move all the other files
          return Promise.all(Object.values(f_info).map(f => zip.file(f.new_path, f.content, f.options)))
            .then(() => zip)
        })
        .then(zip => {
          // remove old files
          return Promise.all(del_list.sort((a, b) => b.length - a.length).map(f => zip.remove(f)))
            .then(() => zip.remove('love.app'))
        })
        .then(zip =>
          // add project files
          Promise.all(Object.keys(add_files).map(old_path =>
            Promise.all([].concat(add_files[old_path]).map(add_file =>
              nwFS.readFile(old_path)
                .then(data => zip.file(add_file, data, { binary: true }))
            ))
          ))
            .then(() => zip)
        )
        .then(zip => zip
          // Info.plist
          .file(`${new_root}/Contents/Info.plist`)
          .async('string')
          .then(content => {
            Object.keys(replacements).forEach(k => {
              content = content.replaceAll(k, replacements[k])
            })
            return content
          })
          .then(content => zip.file(`${new_root}/Contents/Info.plist`, content))
        )
        .then(zip =>
          // write final zip
          new Promise((res, rej) => zip.generateNodeStream({ type: 'nodebuffer', platform: "darwin", streamFiles: true })
            .pipe(nwFS.createWriteStream(out_path))
            .on('finish', () => {
              return res()
            })
          )
        )
        .then(zip => nwFS.remove(love_path))
        .then(() => {
          cb_done()
        })
        .catch(err => {
          cb_err(err)
        })
    }

    if (platform == "web") {
      let html = `
<!DOCTYPE html>
<html lang="en-us">
<head>
	<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>${project_name}</title>
</head>
<body style="margin:0px">
	<div id="my_game"></div>
	<script src="blanke.js"></script>
	<script type="text/javascript">
		(function(){loadGame('${project_name}.data','my_game',${
        app.exportSetting("web_autoplay") == null ? true : app.exportSetting("web_autoplay")
        },${resolution[0]},${resolution[1]},"${app.exportSetting("web_preload_image")}");})();
	</script>
</body>
</html>`;
      let web_stack = app.exportSetting("web_stack");
      let web_memory = app.exportSetting("web_memory");
      let extrajs = mem =>
        `if (!game_loaded) var game_loaded = {};
if (!loadGame) var loadGame = function(data_file, div_id, play_on_focus, width, height, preload_image) {
    if (game_loaded[data_file.split('.').slice(0, -1).join('.')]) return;
    let use_canvas_size = !(width || height);
    width = width || 800;
    height = height || 600;
    let el_parent, el_overlay, el_message, canvas, ctx;
    el_parent = document.getElementById(div_id);
    el_parent.setAttribute("style", "width:" + width + "px;height:" + height + "px;background:#485358;position:relative;overflow:hidden;background-position:center;"+(preload_image && preload_image != "" ? "background-image:url("+preload_image+");" : ""));
    el_overlay = document.createElement("div");
    el_overlay.setAttribute("style", "z-index:2;position:absolute;top:0;left:0;right:0;bottom:0;cursor:pointer;box-shadow: inset 0 0 5em 1em #000;");
    let overlay_inner = function(t) {
        return '<div style="text-align: center;position: absolute;top: 50%;left: 50%;transform: translate(-50%,-50%);font-size: 28px;font-family: Trebuchet MS;color: white;text-shadow: 0px 0px 1px black, 0px 0px 1px black, 0px 0px 1px black, 0px 0px 3px black;padding: 3px;user-select:none;">' + t + '</div>'
    };
    el_overlay.innerHTML = overlay_inner("Loading...");
    el_message = document.createElement("div");
    el_message.setAttribute("style", "z-index:3;position:absolute;top:0;left:0;outline:none;color:white;font-size:12px;text-shadow: 0px 0px 1px black, 0px 0px 1px black, 0px 0px 1px black, 0px 0px 3px black;padding:3px;");
    canvas = document.createElement('canvas');
    canvas.setAttribute("style", "z-index:1;position:absolute;left:0;right:0");
    canvas.tabIndex = 1;
    canvas.addEventListener('keydown', e => {
        e.preventDefault();
        return false;
    });
    canvas.width = width || 800;
    canvas.height = height || 600;
    canvas.oncontextmenu = function(e) {
        e.preventDefault()
    };
    ctx = canvas.getContext('2d');
    el_parent.appendChild(canvas);
    el_parent.appendChild(el_message);
    el_parent.appendChild(el_overlay);
    let TXT = {
        LOAD: 'Loading Game',
        EXECUTE: 'Done loading',
        DLERROR: 'Error while loading game data.\\nCheck your internet connection.',
        NOWEBGL: 'Your browser or graphics card does not seem to support <a href="http://khronos.org/webgl/wiki/Getting_a_WebGL_Implementation">WebGL</a>.<br>Find out how to get it <a href="http://get.webgl.org/">here</a>.',
    };
    let Msg = function(m) {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.fillStyle = '#888';
        for (var i = 0, a = m.split('\\n'), n = a.length; i != n; i++) ctx.fillText(a[i], 20, 20);
    };
    let Fail = function(m) {
        el_parent.removeChild(el_overlay);
        el_message.innerHTML = TXT.NOWEBGL + (m ? m : '')
    };
    let DoExecute = function() {
        Msg(TXT.EXECUTE);
        Module.canvas = canvas.cloneNode(!1);
        Module.canvas.oncontextmenu = function(e) {
            e.preventDefault()
        };
        Module.setWindowTitle = function(title) {};
        Module.pauseMainLoop();
        Module.postRun = function() {
            if (!Module.noExitRuntime) {
                Fail();
                return
            };
            canvas.parentNode.replaceChild(Module.canvas, canvas);
            Txt = Msg = ctx = canvas = null;
            if (play_on_focus) {
                Browser.mainLoop.pause();
            }
            setTimeout(function() {
                if (use_canvas_size) {
                    el_parent.style.width = Module.canvas.widthNative + "px";
                    el_parent.style.height = Module.canvas.heightNative + "px"
                };
                if (play_on_focus) {
                    Browser.mainLoop.pause();
                    el_overlay.innerHTML = overlay_inner("Click to play");
                    el_overlay.onclick = function() {
                        el_overlay.innerHTML = overlay_inner("Loading...")
                        setTimeout(() => {
                          el_parent.removeChild(el_overlay);
                          Module.canvas.focus();
                          Browser.mainLoop.resume()
                        })
                    }
                } else {
                    el_parent.removeChild(el_overlay);
                    Module.canvas.focus()
                }
            })
        };
        Browser.requestAnimationFrame = function(f) {
          window.requestAnimationFrame(f)
        };
        setTimeout(function() {
            Module.run(['/p'])
        }, 50)
    };
    let DoLoad = function() {
        Msg(TXT.LOAD);
        window.onerror = function(e, u, l) {
            Fail(e + '<br>(' + u + ':' + l + ')')
        };
        Module = {
            ALLOW_MEMORY_GROWTH: 1,
            TOTAL_MEMORY: 1024 * 1024 * ${mem},
            TOTAL_STACK: 1024 * 1024 * ${web_stack},
            currentScriptUrl: '-',
            preInit: DoExecute
        };
        var s = document.createElement('script'),
            d = document.documentElement;
        s.src = data_file;
        s.async = !0;
        game_loaded[data_file] = !0;
        s.onerror = function(e) {
            el_parent.removeChild(el_overlay);
            d.removeChild(s);
            Msg(TXT.DLERROR);
            canvas.disabled = !1;
            game_loaded[data_file] = !1
        };
        d.appendChild(s)
    };
    DoLoad()
}`;

      nwFS.readFile(love_path, "base64", (err, game_data) => {
        if (err) console.error(err);
        let gamejs = `FS.createDataFile('/p',0,FS.DEC('${game_data}'),!0,!0,!0)`;

        nwFS.readFile(
          nwPATH.join(app.engine_path, "love.js"),
          "utf-8",
          (err, love_data) => {
            if (err) console.error(err);
            let lovejs = love_data;
            let game_data = Buffer.from(lovejs + gamejs);

            let new_memory = 1;
            while (new_memory < game_data.length / 1000000) new_memory *= 2;
            new_memory *= 2; // add a little extra for good measure ;)
            console.log(
              `exporting web, memory:${
              web_memory === 0 ? new_memory : web_memory
              }, stack size:${web_stack}`
            );

            nwFS.writeFileSync(
              nwPATH.join(os_dir, `blanke.js`),
              new Uint8Array(
                Buffer.from(extrajs(web_memory === 0 ? new_memory : web_memory))
              )
            );
            nwFS.writeFileSync(
              nwPATH.join(os_dir, `${project_name}.data`),
              new Uint8Array(game_data)
            );
            nwFS.removeSync(love_path);

            nwFS.writeFile(
              nwPATH.join(os_dir, "index.html"),
              html,
              "utf-8",
              err => {
                if (err) console.error(err);
                cb_done();
              }
            );
          }
        );
      });
    }
  },
};

let color_vars = {
  r: 'red component (0-1 or 0-255) / hex (#ffffff) / preset (\'blue\')',
  g: 'green component',
  b: 'blue component',
  a: 'optional alpha'
}
let color_prop = '{r,g,b} (0-1 or 0-255) / hex (\'#ffffff\') / preset (\'blue\')';

let prop_z = { prop: 'z', info: 'lower numbers are drawn behind higher numbers' }
let prop_xy = [
  { prop: 'x' },
  { prop: 'y' }
]
let prop_xyz = [
  ...prop_xy,
  prop_z
]
let prop_pixi_point = (name) => ({ prop: name || 'point', info: '{ x, y, set(x, y=x) }' })
let prop_gameobject = [
  ...prop_xyz,
  ...(['angle', 'scalex', 'scaley', 'scale', 'width', 'height', 'offx', 'offy', 'shearx', 'sheary'].map(p => ({ prop: p }))),
  { prop: 'align', info: 'left/right top/bottom center' },
  { prop: 'blendmode', info: '{ mode, alphamode }' },
  { prop: 'uuid' },
  { fn: 'setEffect', vars: { name: '...' } },
  { prop: 'effect' },
  { fn: 'destroy' }
]

// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Lexical_grammar#Keywords
// used Array.from(document.querySelectorAll("#Reserved_keywords_as_of_ECMAScript_2015 + .threecolumns code")).map((v)=>"'"+v.innerHTML+"'").join(',')
module.exports.autocomplete = {
  keywords: ['true', 'false'],
  /*
	'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for', 'function',
	'if', 'in', 'local', 'nil', 'not', 'or', 'repeat', 'return', 'then', 'true',
	'until', 'while'
]*/

  class_list: [
    "Math", "FS", "Game", "Canvas", "Image", "Entity",
    "Input", "Draw", "Color", "Audio", "Effect", "Camera",
    "Map", "Physics", "Hitbox", "State", "Timer", "Window",
    "Net", "Config", "Blanke", "class", "table", "callable"
  ],

  class_extends: {
    'entity': /\bEntity\s*\(\s*[\'\"](\w+)[\'\"],\s*/g,
    'class': /\b(\w+)\s*=\s*class\s*\{/g,
    'callable': /\b(\w+)\s*=\s*callable\s*\{/g
  },

  instance: {
    'entity': /\b(\w+)\s*=\s*Game\.spawn\(\s*[\'\"]<class_name>[\'\"]\s*\)/g,
    'map': /\b(\w+)\s*=\s*Map\.load\([\'\"].+[\'\"]\)/g,
    'canvas': /(@?\w+)\s*(?::|=)\s*Canvas[\s\(]/g
  },

  user_words: {/*
    'var':[
      // single var
      /([a-zA-Z_]\w+?)\s*=\s(?!function|\(\)\s*[-|=]>)/g,
      /(?:local)\s+([a-zA-Z_]\w+)/g,
      /(@?[a-zA-Z_]\w+)/g,
      // comma separated var list
      /(?:let|var)\s+(?:[a-zA-Z_]+[\w\s=]+?,\s*)+([a-zA-Z_]\w+)(?!\s*=)/g
    ],
    */
    'fn': [
      // var = function
      /([a-zA-Z_]\w+?)\s*=\s(?:function|\(\)\s*[-|=]>)/g,
      // function var()
      /function\s+([a-zA-Z_]\w+)\s*\(/g
    ]
  },

  image: [
    /Image\.animation\s*\(\s*['"]([\w\s\/.-]+)['"]\s*(?:,[\s\{]*(['"\w\s\/.\-=\s,{}]+)\s*})?\s*\)/g
  ],

  entity_using_image: [
    /Entity\s*\(\s*[\'\"](\w+)[\'\"],.*[\s,{]animation[\s=]+['"]([\w\s\/.-]+)['"]/g,
    /Entity\s*\(\s*[\'\"](\w+)[\'\"],.*[\s,{]image[\s=]+['"]([\w\s\/.-]+)['"]/g,
    /Entity\s*\(\s*[\'\"](\w+)[\'\"],.*[\s,{]animations[\s=]+\{\s*['"]([\w\s\/.-]+)['"]/g,
    /Entity\s*\(\s*[\'\"](\w+)[\'\"],.*[\s,{]images[\s=]+\{\s*['"]([\w\s\/.-]+)['"]/g,
  ],

  sprite_align: [
    /Entity\s*\(\s*[\'\"](\w+)[\'\"],.*[^\.]align[\s=]+['"]([\w\s\/.-]+)['"]/g
  ],

  this_ref: {
    'blanke-entity-instance': /\bEntity\s*\(\s*[\'\"](\w+)[\'\"],\s*/g
  },

  this_keyword: 'self',

  /*
    { fn: "name", info, vars }
    { prop: "name", info }

    - info: "description"
    - vars: { arg1: 'default', arg2: 'description', etc: '' }
  */
  hints: {
    "global": [
      { fn: "Draw", vars: { args: '...' } },
      { fn: 'switch', vars: { v: '', choices_t: '{ choice1 = function() end, ... }' } },
      { fn: 'copy', vars: { t: '' }, info: 'returns deepcopy of table' },
      { fn: 'is_object', vars: { v: '' }, info: 'is v an instance of a class' },
      { fn: 'encrypt', vars: { str: '', code: 'hashing key', seed: 'opt number' } },
      { fn: 'decrypt', vars: { hashed_str: '', code: 'hashing key used to encrypt', seed: 'opt number used to encrypt' } }
    ],
    "blanke-table": [
      { fn: 'update', vars: { old: '', 'new': '', keys: 'opt' } },
      { fn: 'keys', vars: { t: '' } },
      { fn: 'every', vars: { t: '' } },
      { fn: 'some', vars: { t: '' } },
      { fn: 'len', vars: { t: '' } },
      { fn: 'hasValue', vars: { t: '', val: '' } },
      { fn: 'slice', vars: { t: '', start: 'opt 1', end: 'opt #t' }, info: 'returns segment of table' },
      { fn: 'defaults', vars: { t: '', defaults_t: '' } },
      { fn: 'append', vars: { t: '', new_t: '' } },
      { fn: 'filter', vars: { t: '', fn: '(item, index) => true to keep value, false to remove' } },
      { fn: 'random', vars: { t: '' } },
      { fn: 'includes', vars: { t: '', val: '' } }
    ],
    "blanke-math": [
      { fn: 'seed', vars: { low: 'opt', high: 'opt' }, args: 'set/get rng seed' },
      { fn: 'random', vars: { min: 'opt', max: 'opt' } },
      { fn: 'indexTo2d', vars: { i: '', col: '' } },
      { fn: 'getXY', vars: { angle: '', dist: '' } },
      { fn: 'distance', vars: { x1: '', y1: '', x2: '', y2: '' } },
      { fn: 'lerp', vars: { a: '', b: '', t: '' } },
      { fn: 'sinusoidal', vars: { min: '', max: '', speed: '', offset: 'opt' } },
      { fn: 'angle', vars: { x1: '', y1: '', x2: '', y2: '' }, args: 'returns angle between two points abs(atan2)' },
      { fn: 'pointInShape', vars: { shape: '{x1,y1,x2,y2,...}', x: '', y: '' } }
    ],
    "blanke-fs": [
      { fn: 'basename', vars: { path: '' } },
      { fn: 'dirname', vars: { path: '' } },
      { fn: 'extname', vars: { path: '' }, info: 'returns extension with period' },
      { fn: 'removeExt', vars: { path: '' }, info: 'removes .extension' },
      { fn: 'ls', vars: { path: '' }, info: 'lists files in path' }
    ],
    "blanke-game": [
      { prop: 'options' },
      { prop: 'width' },
      { prop: 'height' },
      { prop: 'win_width' },
      { prop: 'win_height' },
      { prop: 'config' },
      { fn: 'res', vars: { type: 'image/audio/map', file: '' } },
      { fn: 'spawn', vars: { classname: '', args: 'opt' } },
      { fn: 'setBackgroundColor', vars: { r: '', g: '', b: '', a: '' } },
      { prop: 'updatables' },
      { prop: 'drawables' }
    ],
    "blanke-canvas-instance": [
      { fn: 'resize', vars: { w: '', h: '' } },
      { fn: 'drawTo', vars: { obj: 'GameObject or function' } }
    ],
    "blanke-image": [
      { fn: 'info', vars: { name: '' } },
      { fn: 'animation', vars: { file: '', animations: '{name,}', global_options: '' } }
    ],
    "blanke-input": [
      { fn: 'pressed', vars: { name: '' } },
      { fn: 'released', vars: { name: '' } }
    ],
    "blanke-draw": [
      { fn: 'color' },
      { fn: 'crop', vars: { x: '', y: '', w: '', h: '' } },
      { fn: 'reset', vars: { only: 'opt.color / transform / crop' } },
      { fn: 'push' },
      { fn: 'pop' },
      { fn: 'stack', vars: { fn: '' } },
      { fn: 'hexToRgb', vars: { hex: 'string (#fff / #ffffff)' } }
    ],
    "blanke-audio": [
      { fn: 'play', vars: { names: 'etc' } },
      { fn: 'stop', vars: { names: 'etc' } },
      { fn: 'isPlaying', vars: { name: '' } }
    ],
    "blanke-effect": [
      { fn: 'new', vars: { options: '{ vars, code, effect, vertex }' } }
    ],
    "blanke-camera": [
      { fn: 'get', vars: { name: '' } },
      { fn: 'attach', vars: { name: '' } },
      { fn: 'detach' },
      { fn: 'use', vars: { name: '', fn: '' }, info: 'attach -> fn -> detach' }
    ],
    "blanke-map": [
      { fn: 'load', vars: { file: '' } },
      { fn: 'config', vars: { opt: '' } }
    ],
    "blanke-map-instance": [
      { fn: 'addTile', vars: { file: '', x: '', y: '', tx: '', ty: '', tw: '', th: '', layer: 'opt' } },
      { fn: 'spawnEntity', vars: { object_name: '', x: '', y: '', layer: 'opt' } }
    ],
    "blanke-physics": [
      { fn: 'world', vars: { name: '', config: 'opt' } },
      { fn: 'joint', vars: { name: '', config: 'opt' } },
      { fn: 'body', vars: { name: '', config: 'opt' } },
      { fn: 'setGravity', vars: { body: '', angle: 'degrees', dist: '' } }
    ],
    "blanke-hitbox": [
      { fn: 'add', vars: { obj: 'must have x/y' } },
      { fn: 'move', vars: { obj: '' }, info: 'call after changing x/y/hit_area' },
      { fn: 'adjust', vars: { obj: '', left: '', top: '', width: '', height: '' }, info: 'set offsets for a hitbox' },
      { fn: 'remove', vars: { obj: '' } },
      { fn: 'at', vars: { x: '', y: '' } },
      { fn: 'within', vars: { x: '', y: '', w: '', h: '' } },
      { fn: 'sight', vars: { x1: '', y1: '', x2: '', y2: '' } },
      { prop: 'debug', info: 'draw hitboxes' }
    ],
    "blanke-net": [

    ],
    "blanke-timer": [
      { fn: "after", vars: { t: 'seconds', fn: 'return true to restart the timer' } },
      { fn: "every", vars: { t: 'seconds', fn: 'return true to destroy the timer' } }
    ]
  }
}
