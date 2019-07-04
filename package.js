const packager = require('electron-packager');
packager({
    dir: 'projects/dodgem/dist/mac',
    out: 'src/binaries',
    arch: 'all',
    platform: 'all',
    overwrite: true,
    icon: 'src/logo',
    ignore: [
        'love2d','projects','Makefile',
        'package\\.js\\b','error\\.txt','blankejs\\.code\\-workspace',
        'pnpm\\-lock\\.yaml','shrinkwrap\\.yaml',
        '\\.vscode','\\.gitignore'
    ]
})
.then(appPaths => {

});