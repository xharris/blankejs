const writeConf = () => {
    if (app.projSetting('write_conf'))
        nwFS.writeFileSync(
            nwPATH.join(app.getAssetPath('scripts'),'conf.lua'),
`io.stdout:setvbuf('no')
package.path = package.path .. ";${['/?.lua','/?/init.lua','/lua/?/init.lua','/lua/?.lua','/plugins/?/init.lua','/plugins/?.lua'].map(p => app.ideSetting('engine_path')+p).join(';')}"
require "blanke"
function love.conf(t)
    t.console = true
    --t.window = false
end
`)
}

const exportConf = () => app.projSetting('write_conf') ? `
require "blanke"
function love.conf(t)

end
` : null;

const checkOS = (target_os) => {
    if (app.projSetting('export').os != target_os) {
        app.projSetting('export').os = target_os
        app.saveSettings();
    }
}

module.exports.engine = {
    game_preview_enabled: false,
    main_file: 'main.lua',
    file_ext: ['lua'],
    language: 'lua',
    project_settings: [
        [ 'write_conf', 'checkbox', {default:true, label: 'auto-generate conf.lua'} ]
    ],
    export_settings: [
        ['window/rendering'],
        ['filter','select',{'choices':['linear','nearest'],default:'linear'}],
        ...(['frameless','scale','resizable'].map((o)=>[o,'checkbox',{default:false}])),
        ['web'],
        [ 'web_autoplay', 'checkbox', {label:'autoplay',defalt:false}],
        [ 'web_memory', 'number', {label:'memory size',default:24}],
        [ 'web_stack', 'number', {label:'stack size',default:2}],
    ],
    get script_path () { return app.project_path },
    plugin_info_key: (k) => `--\s*${k}\s*:\s*(.+)`,
    code_associations: [
        [
            /Entity\s*[\"\'](\w+)[\"\']/g,
            "entity"
        ],
        [
            /State\(\"(\w+)\"/g,
            "state"
        ]
    ],
    fn_trigger: ':',
	add_script_templates: {
		'script': ``
    },
    entity_sprite_parse: (str_line, info, cb) => {
		// use the first frame        
        let re_rows = /rows\s*=\s*(\d+)/;
        let re_cols = /cols\s*=\s*(\d+)/;
        let re_offx = /offx\s*=\s*(\d+)/;
        let re_offy = /offy\s*=\s*(\d+)/;
        let re_frames = /frames\s*=\s*\{[\s'"]*?(\d+)/;

        /*
		let match;
		if (match = re_frame_size.exec(text.replace(re_comment,''))) {
			info.cropped = true;
			info.frame_size = [parseInt(match[1]),parseInt(match[2])];
		} else {
			// get image size
			let img = new Image();
			img.onload = () => {
				info.frame_size = [img.width, img.height];
				cb(null, info);
			}
			img.src = 'file://'+info.path;
		}
		if (match = re_offset.exec(text.replace(re_comment,''))) 
			info.offset = [parseInt(match[1]),parseInt(match[2])];

		if (match = re_frame.exec(text.replace(re_comment,''))) 
			info.frames = parseInt(match[1]);

		if (match = re_spacing.exec(text.replace(re_comment,''))) {
			info.offset[0] += parseInt(match[1]);
			info.offset[1] += parseInt(match[1]);
		}
        if (info.cropped) cb(info);
        */
    },
    play: (options) => {
        // checkOS('ide');
        writeConf();
        let eng_path = 'love'; // linux, mac?
        if (app.os == 'win') eng_path = nwPATH.join(app.ideSetting('engine_path'), 'lovec');
        if (app.os == 'linux') {
            nwFS.removeSync(nwPATH.join(app.project_path, 'love2d'));
            nwFS.symlinkSync(nwPATH.relative(app.project_path, app.ideSetting('engine_path')), nwPATH.join(app.project_path, 'love2d'));
        }
        let child = spawn(eng_path, ['.'], { cwd: app.getAssetPath('scripts') });
        let con = new Console(true);
        child.stdout.on('data', data => {
            data = data.toString().replace(/Could not open device.\s*/,"").trim();
            data.split(/[\r\n]+/).forEach(l => con.log(l))
        });
        child.stderr.on('data', data => {
            app.error(data);
        });
        child.on('close', () => {
            nwFS.removeSync(nwPATH.join(app.project_path, 'love2d'));
            con.tryClose();
        })
    },
    export_targets: {
        "love":false,
        "windows":true,
        // "web":true
    },
    export_assets: false,
    bundle: (dir, target_os, cb_done) => {
        // checkOS(target_os);
        let love_path = nwPATH.join(dir, app.projSetting("export").name+".love");
        let engine_path = app.ideSetting("engine_path");

        let output = nwFS.createWriteStream(love_path);
        let archive = nwZIP('zip',{ /* zlib: { level: 9} */});

        output.on('close', cb_done);
        archive.pipe(output);

        let str_conf = exportConf();
        if (str_conf)
            archive.append(str_conf, { name: 'conf.lua' });
        archive.glob("**/*", { cwd: app.project_path, ignore: ["*.css","dist","dist/**/*",str_conf ? "conf.lua" : null] });
        archive.glob("**/*.lua", { cwd: nwPATH.join(engine_path) });
        archive.finalize();
    },
    extra_bundle_assets: {
        windows: ['love.dll','lua51.dll','mpg123.dll','msvcp120.dll','msvcr120.dll','OpenAL32.dll','SDL2.dll'].map(p => '<engine_path>/'+p)
    },
    setupBinary: (os_dir, temp_dir, platform, arch, cb_done, cb_err) => {
        let love_path = nwPATH.join(temp_dir, app.projSetting("export").name+".love")
        let engine_path = app.ideSetting('engine_path');
        let project_name = app.projSetting('export').name;

        let res = app.projSetting("scale");
        let aspect_ratio = [4,3];
        let res_list = [512,640,800,1024,1280,1366,1920];
        resolution = [
            res_list[res],
            res_list[res] / aspect_ratio[0] * aspect_ratio[1]
        ];
        
        if (platform == 'windows') {
            let exe_path = nwPATH.join(os_dir, project_name+".exe");
            // TODO: test on mac/linux
            // copy /b love.exe+game.love game.exe
            let f_loveexe = nwFS.createReadStream(nwPATH.join(engine_path,"love.exe"), {flags:'r', encoding:'binary'});
            let f_gamelove = nwFS.createReadStream(love_path, {flags:'r', encoding:'binary'});
            let f_gameexe = nwFS.createWriteStream(exe_path, {flags:'w', encoding:'binary'});
            // set up callbacks
            f_loveexe.on('end', ()=>{ 
                f_gamelove.pipe(f_gameexe); 
                // finished all merging
                nwFS.remove(love_path, () => {
                    cb_done();
                });
            })
            // start merging
            f_loveexe.pipe(f_gameexe, {end:false});
        }

        if (platform == 'web') {
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
		(function(){loadGame('${project_name}.data','my_game',${!app.projSetting("export").web_autoplay || true},${resolution[0]},${resolution[1]});})();
	</script>
</body>
</html>`;
            let web_stack = app.projSetting('export').web_stack;
            let web_memory = app.projSetting('export').web_memory;
            let extrajs = `if(!game_loaded)var game_loaded={};if(!loadGame)var loadGame=function(data_file,div_id,play_on_focus,width,height){if(game_loaded['${project_name}'])return;let use_canvas_size=!(width||height);width=width||800;height=height||600;let el_parent,el_overlay,el_message,canvas,ctx;el_parent=document.getElementById(div_id);el_parent.setAttribute("style","width:"+width+"px;height:"+height+"px;background:#485358;position:relative");el_overlay=document.createElement("div");el_overlay.setAttribute("style","z-index:2;position:absolute;top:0;left:0;right:0;bottom:0;cursor:pointer;box-shadow: inset 0 0 5em 1em #000;");let overlay_inner=function(t){return'<div style="text-align: center;position: absolute;top: 50%;left: 50%;transform: translate(-50%,-50%);font-size: 28px;font-family: Trebuchet MS;color: white;text-shadow: 0px 0px 1px black, 0px 0px 1px black, 0px 0px 1px black, 0px 0px 3px black;padding: 3px;user-select:none;">'+t+'</div>'};el_overlay.innerHTML=overlay_inner("Loading...");el_message=document.createElement("div");el_message.setAttribute("style","z-index:3;position:absolute;top:0;left:0;outline:none;color:white;font-size:12px;text-shadow: 0px 0px 1px black, 0px 0px 1px black, 0px 0px 1px black, 0px 0px 3px black;padding:3px;");canvas=document.createElement('canvas');canvas.setAttribute("style","z-index:1;position:absolute;left:0;right:0");canvas.width=width||800;canvas.height=height||600;canvas.oncontextmenu=function(e){e.preventDefault()};ctx=canvas.getContext('2d');el_parent.appendChild(canvas);el_parent.appendChild(el_message);el_parent.appendChild(el_overlay);let TXT={LOAD:'Loading Game',EXECUTE:'Done loading',DLERROR:'Error while loading game data.\\nCheck your internet connection.',NOWEBGL:'Your browser or graphics card does not seem to support <a href="http://khronos.org/webgl/wiki/Getting_a_WebGL_Implementation">WebGL</a>.<br>Find out how to get it <a href="http://get.webgl.org/">here</a>.',};let Msg=function(m){ctx.clearRect(0,0,canvas.width,canvas.height);ctx.fillStyle='#888';for(var i=0,a=m.split('\\n'),n=a.length;i!=n;i++)ctx.fillText(a[i],20,20);};let Fail=function(m){el_parent.removeChild(el_overlay);el_message.innerHTML=TXT.NOWEBGL+(m?m:'')};let DoExecute=function(){Msg(TXT.EXECUTE);Module.canvas=canvas.cloneNode(!1);Module.canvas.oncontextmenu=function(e){e.preventDefault()};Module.setWindowTitle=function(title){};Module.postRun=function(){if(!Module.noExitRuntime){Fail();return};canvas.parentNode.replaceChild(Module.canvas,canvas);Txt=Msg=ctx=canvas=null;setTimeout(function(){if(use_canvas_size){el_parent.style.width=Module.canvas.widthNative+"px";el_parent.style.height=Module.canvas.heightNative+"px"};if(play_on_focus){Browser.mainLoop.pause();el_overlay.innerHTML=overlay_inner("Click to play");el_overlay.onclick=function(){el_parent.removeChild(el_overlay);Module.canvas.focus();Browser.mainLoop.resume()}}else{el_parent.removeChild(el_overlay);Module.canvas.focus()}},1)};Browser.requestAnimationFrame=function(f){window.requestAnimationFrame(f)};setTimeout(function(){Module.run(['/p'])},50)};let DoLoad=function(){Msg(TXT.LOAD);window.onerror=function(e,u,l){Fail(e+'<br>('+u+':'+l+')')};Module={ALLOW_MEMORY_GROWTH:1,TOTAL_MEMORY:1024*1024*${web_memory},TOTAL_STACK:1024*1024*${web_stack},currentScriptUrl:'-',preInit:DoExecute};var s=document.createElement('script'),d=document.documentElement;s.src=data_file;s.async=!0;game_loaded[data_file]=!0;s.onerror=function(e){el_parent.removeChild(el_overlay);d.removeChild(s);Msg(TXT.DLERROR);canvas.disabled=!1;game_loaded[data_file]=!1};d.appendChild(s)};DoLoad()}`;
            nwFS.readFile(love_path,'base64',(err, game_data)=>{
                if (err) console.error(err);	
                let gamejs = `FS.createDataFile('/p',0,FS.DEC('${game_data}'),!0,!0,!0)`;
                
                nwFS.readFile(nwPATH.join(cwd(),'src','includes','love.js'),'utf-8',(err, love_data)=>{
                    if (err) console.error(err);
                    let lovejs = love_data;

                    nwFS.writeFileSync(nwPATH.join(os_dir,`blanke.js`),new Uint8Array(Buffer.from(extrajs)));
                    nwFS.writeFileSync(nwPATH.join(os_dir,`${project_name}.data`),new Uint8Array(Buffer.from(lovejs + gamejs)));
                    nwFS.removeSync(love_path);
                        
                    nwFS.writeFile(nwPATH.join(os_dir,'index.html'),html,'utf-8',(err)=>{
                        if (err) console.error(err);
                        cb_done();
                    });
                });
            });
        }
    }
}
