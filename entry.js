const elec = require('electron');

let main_window;
elec.app.on('open-file', (e, path)=>{
    if (main_window)
        ;//main_window.webContents.send('open-file', path);
})
elec.app.commandLine.appendSwitch('enable-gpu-rasterization', 'true')
elec.app.on('ready', function(){
    let display = elec.screen.getPrimaryDisplay();

    main_window = new elec.BrowserWindow({
        x: display.bounds.x + ((display.bounds.width - 800)/2),
        y: display.bounds.y + ((display.bounds.height - 600)/2),
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
        },
        show: false
    })
    if (main_window.setWindowButtonVisibility)
        main_window.setWindowButtonVisibility(false);
    
    // main_window.webContents.openDevTools();		
    main_window.loadFile(`src/index.html`);
    main_window.on('close', e => {
        main_window.webContents.send('close', e);
        e.preventDefault();
    });
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
