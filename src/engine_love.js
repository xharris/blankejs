const writeConf = () => {
    if (app.projSetting('write_conf'))
        nwFS.writeFileSync(
            nwPATH.join(app.getAssetPath('scripts'),'conf.lua'),
`io.stdout:setvbuf('no')
package.path = package.path .. ";${['/?.lua','/lua/?/init.lua','/lua/?.lua','/plugins/?/init.lua','/plugins/?.lua'].map(p => app.ideSetting('engine_path')+p).join(';')}"
require "blanke"
function love.conf(t)
    t.console = true
    --t.window = false
end
`)
}

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
        ['scale_mode','select',{'choices':['linear','nearest']}],
        ...(['frameless','scale','resizable'].map((o)=>[o,'checkbox']))
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
            data = data.toString().replace(/Could not open device.\s*/,"");
            con.log(data);
        });
        child.on('close', () => {
            con.tryClose();
        })
    }
}