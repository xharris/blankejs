const { spawn } = require("child_process");
const nwZIP = require("archiver"); // used for zipping

const re_sprite_props = /(\w+)[=\{\s'"]+([\w\-\.\s]+)[\}\s'",]+?/g;

const generalConf = () => `
    t.window.title = "${app.exportSetting("name")}"
    -- t.gammacorrect = nil
`;

const runConf = () => {
  if (app.projSetting("write_conf")) {
    nwFS.writeFileSync(
      nwPATH.join(app.getAssetPath("scripts"), "conf.lua"),
      `io.stdout:setvbuf('no')
package.path = package.path .. ";${[
        "/?.lua",
        "/?/init.lua",
        "/lua/?/init.lua",
        "/lua/?.lua",
        "/plugins/?/init.lua",
        "/plugins/?.lua",
      ]
        .map(p => app.ideSetting("engine_path") + p)
        .join(";")}"
require "blanke"
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
require "blanke"
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

const re_loverun = /\-\-BEGIN\:LOVE\.RUN.*\-\-END\:LOVE\.RUN/g;

module.exports.engine = {
  game_preview_enabled: false,
  main_file: "main.lua",
  file_ext: ["lua"],
  language: "lua",
  project_settings: [
    [
      "write_conf",
      "checkbox",
      { default: true, label: "auto-generate conf.lua" },
    ],
  ],
  export_settings: [
    ["window/rendering"],
    ["filter", "select", { choices: ["linear", "nearest"], default: "linear" }],
    ...["frameless", "scale", "resizable"].map(o => [
      o,
      "checkbox",
      { default: false },
    ]),
    ["vsync", "select", { choices: ["on", "off", "adaptive"], default: "on" }],
    ["web"],
    ["web_autoplay", "checkbox", { label: "autoplay", defalt: false }],
    ["web_memory", "number", { label: "memory size", default: 24 }],
    ["web_stack", "number", { label: "stack size", default: 2 }],
    [
      "override_game_size",
      "checkbox",
      {
        default: false,
        title: "if enabled, web container will be the size given below",
      },
    ],
    ["web_game_size", "number", { inputs: 2, default: [800, 600] }],
  ],
  get script_path() {
    return app.project_path;
  },
  plugin_info_key: k => `--\s*${k}\s*:\s*(.+)`,
  code_associations: [
    [/Entity\s*[\"\'](\w+)[\"\']/g, "entity"],
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
    if (app.os == "win")
      eng_path = nwPATH.join(app.ideSetting("engine_path"), "lovec");
    if (app.os == "linux") {
      nwFS.removeSync(nwPATH.join(app.project_path, "love2d"));
      nwFS.symlinkSync(
        nwPATH.relative(app.project_path, app.ideSetting("engine_path")),
        nwPATH.join(app.project_path, "love2d")
      );
    }
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
  export_targets: {
    love: false,
    windows: true,
    web: true,
  },
  export_assets: false,
  bundle: (dir, target_os, cb_done) => {
    // checkOS(target_os);
    let love_path = nwPATH.join(dir, app.projSetting("export").name + ".love");
    let engine_path = app.ideSetting("engine_path");

    let output = nwFS.createWriteStream(love_path);
    let archive = nwZIP("zip", { zlib: { level: 9 } });

    output.on("close", cb_done);
    archive.pipe(output);

    let str_conf = exportConf(target_os);
    if (str_conf) archive.append(str_conf, { name: "conf.lua" });
    archive.glob("**/*", {
      cwd: app.project_path,
      ignore: ["*.css", "dist", "dist/**/*", ...(str_conf ? ["conf.lua"] : [])],
    });
    archive.glob("**/*.lua", { cwd: nwPATH.join(engine_path) });
    archive.finalize();
  },
  extra_bundle_assets: {
    windows: [
      "love.dll",
      "lua51.dll",
      "mpg123.dll",
      "msvcp120.dll",
      "msvcr120.dll",
      "OpenAL32.dll",
      "SDL2.dll",
    ].map(p => "<engine_path>/" + p),
    web: ["<engine_path>/favicon.ico"],
  },
  setupBinary: (os_dir, temp_dir, platform, arch, cb_done, cb_err) => {
    let export_settings = app.projSetting("export");
    let love_path = nwPATH.join(temp_dir, export_settings.name + ".love");
    let engine_path = app.ideSetting("engine_path");
    let project_name = export_settings.name;

    let resolution = getGameSize(platform);

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

    if (platform == "web") {
      let html = `
<!DOCTYPE html>
<html lang="en-us">
<head>
	<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>${project_name}</title>
</head>
<body>
	<div id="my_game"></div>
	<script src="blanke.js"></script>
	<script type="text/javascript">
		(function(){loadGame('${project_name}.data','my_game',${
        !app.projSetting("export").web_autoplay || true
      },${resolution[0]},${resolution[1]});})();
	</script>
</body>
</html>`;
      let web_stack = app.projSetting("export").web_stack;
      let web_memory = app.projSetting("export").web_memory;
      let extrajs = mem =>
        `if(!game_loaded)var game_loaded={};if(!loadGame)var loadGame=function(data_file,div_id,play_on_focus,width,height){if(game_loaded[data_file.split('.').slice(0,-1).join('.')])return;let use_canvas_size=!(width||height);width=width||800;height=height||600;let el_parent,el_overlay,el_message,canvas,ctx;el_parent=document.getElementById(div_id);el_parent.setAttribute("style","width:"+width+"px;height:"+height+"px;background:#485358;position:relative;overflow:hidden;");el_overlay=document.createElement("div");el_overlay.setAttribute("style","z-index:2;position:absolute;top:0;left:0;right:0;bottom:0;cursor:pointer;box-shadow: inset 0 0 5em 1em #000;");let overlay_inner=function(t){return'<div style="text-align: center;position: absolute;top: 50%;left: 50%;transform: translate(-50%,-50%);font-size: 28px;font-family: Trebuchet MS;color: white;text-shadow: 0px 0px 1px black, 0px 0px 1px black, 0px 0px 1px black, 0px 0px 3px black;padding: 3px;user-select:none;">'+t+'</div>'};el_overlay.innerHTML=overlay_inner("Loading...");el_message=document.createElement("div");el_message.setAttribute("style","z-index:3;position:absolute;top:0;left:0;outline:none;color:white;font-size:12px;text-shadow: 0px 0px 1px black, 0px 0px 1px black, 0px 0px 1px black, 0px 0px 3px black;padding:3px;");canvas=document.createElement('canvas');canvas.setAttribute("style","z-index:1;position:absolute;left:0;right:0");canvas.tabIndex=1;canvas.addEventListener('keydown',e=>{e.preventDefault();return false;});canvas.width=width||800;canvas.height=height||600;canvas.oncontextmenu=function(e){e.preventDefault()};ctx=canvas.getContext('2d');el_parent.appendChild(canvas);el_parent.appendChild(el_message);el_parent.appendChild(el_overlay);let TXT={LOAD:'Loading Game',EXECUTE:'Done loading',DLERROR:'Error while loading game data.\\nCheck your internet connection.',NOWEBGL:'Your browser or graphics card does not seem to support <a href="http://khronos.org/webgl/wiki/Getting_a_WebGL_Implementation">WebGL</a>.<br>Find out how to get it <a href="http://get.webgl.org/">here</a>.',};let Msg=function(m){ctx.clearRect(0,0,canvas.width,canvas.height);ctx.fillStyle='#888';for(var i=0,a=m.split('\\n'),n=a.length;i!=n;i++)ctx.fillText(a[i],20,20);};let Fail=function(m){el_parent.removeChild(el_overlay);el_message.innerHTML=TXT.NOWEBGL+(m?m:'')};let DoExecute=function(){Msg(TXT.EXECUTE);Module.canvas=canvas.cloneNode(!1);Module.canvas.oncontextmenu=function(e){e.preventDefault()};Module.setWindowTitle=function(title){};Module.postRun=function(){if(!Module.noExitRuntime){Fail();return};canvas.parentNode.replaceChild(Module.canvas,canvas);Txt=Msg=ctx=canvas=null;setTimeout(function(){if(use_canvas_size){el_parent.style.width=Module.canvas.widthNative+"px";el_parent.style.height=Module.canvas.heightNative+"px"};if(play_on_focus){Browser.mainLoop.pause();el_overlay.innerHTML=overlay_inner("Click to play");el_overlay.onclick=function(){el_parent.removeChild(el_overlay);Module.canvas.focus();Browser.mainLoop.resume()}}else{el_parent.removeChild(el_overlay);Module.canvas.focus()}},1)};Browser.requestAnimationFrame=function(f){window.requestAnimationFrame(f)};setTimeout(function(){Module.run(['/p'])},50)};let DoLoad=function(){Msg(TXT.LOAD);window.onerror=function(e,u,l){Fail(e+'<br>('+u+':'+l+')')};Module={ALLOW_MEMORY_GROWTH:1,TOTAL_MEMORY:1024*1024*${mem},TOTAL_STACK:1024*1024*${web_stack},currentScriptUrl:'-',preInit:DoExecute};var s=document.createElement('script'),d=document.documentElement;s.src=data_file;s.async=!0;game_loaded[data_file]=!0;s.onerror=function(e){el_parent.removeChild(el_overlay);d.removeChild(s);Msg(TXT.DLERROR);canvas.disabled=!1;game_loaded[data_file]=!1};d.appendChild(s)};DoLoad()}`;

      nwFS.readFile(love_path, "base64", (err, game_data) => {
        if (err) console.error(err);
        let gamejs = `FS.createDataFile('/p',0,FS.DEC('${game_data}'),!0,!0,!0)`;

        nwFS.readFile(
          nwPATH.join(cwd(), "src", "includes", "love.js"),
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
