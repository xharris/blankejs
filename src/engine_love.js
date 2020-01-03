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

const engine = {
    game_preview_enabled: false,
    main_file: 'main.lua',
    file_ext: ['lua'],
    language: 'lua',
    project_settings: [
        [ 'write_conf', 'checkbox', {default:true, label: 'write conf.lua'} ]
    ],
    export_settings: [
        ['window/rendering'],
        ['scale_mode','select',{'choices':['linear','nearest'],default:'linear'}],
        ...(['frameless','scale','resizable'].map((o)=>[o,'checkbox',{default:false}]))
    ],
    get script_path () { return app.project_path },
    plugin_info_key: (k) => `--\s*${k}\s*:\s*(.+)`,
    code_associations: [
        [
            /Entity\s*[\"\'](\w+)[\"\']/g,
            "entity"
        ],
    ],
	add_script_templates: {
		'script': `import Entity, Game, Canvas, Input, Draw, Audio, Effect, Math, Map from require "blanke"`
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
        writeConf();
        let eng_path = 'love'; // linux, mac?
        if (app.os == 'win') eng_path = nwPATH.join(app.ideSetting('engine_path'), 'lovec');

        let child = spawn(eng_path, ['.'], { cwd: app.getAssetPath('scripts') });
        let con = new Console(true);
        child.stdout.on('data', data => {
            data = data.toString().replace(/Could not open device.\s*/,"").trim();
            data.split(/[\r\n]+/).forEach(l => con.log(l))
        });
        child.on('close', () => {
            con.tryClose();
        })
    },
    export_targets: {
        "love":false,
        "windows":true
    },
    export_assets: false,
    bundle: (dir, target_os, cb_done) => {
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
    }
}