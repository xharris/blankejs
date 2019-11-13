const elec = require('electron');


let main_window;
elec.app.on('open-file', (e, path)=>{
    if (main_window)
        ;//main_window.webContents.send('open-file', path);
})
elec.app.commandLine.appendSwitch('enable-gpu-rasterization', 'true')
elec.app.on('ready', function(){
    main_window = new elec.BrowserWindow({
        width: 800,
        height: 600,
        frame: false,
        titleBarStyle: 'hidden',
        backgroundColor: '#fff',
        webPreferences: {
            nodeIntegration: true,
            webgl: true,
            webSecurity: false,
            experimentalFeatures: true,
            experimentalCanvasFeatures: true
        }
    })
    if (main_window.setWindowButtonVisibility)
        main_window.setWindowButtonVisibility(false);
    main_window.loadFile(`src/index.html`);
    /*
    main_window.webContents.on('new-window', function(e, url) {
        e.preventDefault();
        console.log(url,'target',e.target.target);
        if (url.length > 1)
            require('electron').shell.openExternal(url);
    });*/

    // main_window.webContents.openDevTools();
});

elec.app.commandLine.appendSwitch('ignore-gpu-blacklist');

process.on('uncaughtException', (err) => {
    console.log(err);
})
