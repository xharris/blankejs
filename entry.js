const elec = require('electron');

const WIN_WIDTH = 1000;
const WIN_HEIGHT = 700;

let main_window;
elec.app.on('open-file', (e, path)=>{
    if (main_window)
        ;//main_window.webContents.send('open-file', path);
})
elec.app.commandLine.appendSwitch('enable-gpu-rasterization', 'true')
elec.app.on('ready', function(){
    let display = elec.screen.getPrimaryDisplay();

    main_window = new elec.BrowserWindow({
        x: display.bounds.x + ((display.bounds.width - WIN_WIDTH)/2),
        y: display.bounds.y + ((display.bounds.height - WIN_HEIGHT)/2),
        width: WIN_WIDTH,
        height: WIN_HEIGHT,
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
    
    //main_window.webContents.openDevTools();		
    main_window.loadFile(`src/index.html`);
    main_window.on('close', e => {
        main_window.webContents.send('close', e);
        e.preventDefault();
    });
    
    main_window.webContents.on('new-window', function(e, url) {
        e.preventDefault();
        console.log(url);
        if (url.length > 1)
            require('electron').shell.openExternal(url);
    });
});

elec.app.commandLine.appendSwitch('ignore-gpu-blacklist');

process.on('uncaughtException', (err) => {
    console.log(err);
})
