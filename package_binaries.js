const packager = require('electron-packager');

packager({
    dir: 'projects/dodgem/dist/mac',
    out: 'projects/dodgem/dist',/*
    arch: 'all',
    platform: 'all',*/
    overwrite: true,
    icon: 'src/logo'
})
.then(appPaths => {
    
});
