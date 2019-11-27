const writeConf = () => {
    nwFS.writeFileSync(
        nwPATH.join(app.getAssetPath('scripts'),'conf.lua'),
`io.stdout:setvbuf('no')
package.path = package.path .. ";${app.ideSetting('engine_path')}/?.lua"
require 'moonscript'
package.moonpath = package.moonpath .. ";${app.ideSetting('engine_path')}/?.moon"
function love.conf(t)
    t.console = true
end
`)
}

const engine = {
    game_preview_enabled: false,
    main_file: 'main.lua',
    file_ext: ['moon','lua'],
    language: 'moonscript',
    get script_path () { return app.project_path },
    code_associations: [
        [
            /Entity\s*[\"\'](\w+)[\"\']/g,
            "entity"
        ],
    ],
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