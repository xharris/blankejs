const elec = require('electron');

elec.app.on('ready', function(){
    let main_window = new elec.BrowserWindow({
        width: 800,
        height: 600,
        frame: false,
        titleBarStyle: 'hidden',
        webPreferences: {
            nodeIntegration: true
        }
    })
    if (main_window.setWindowButtonVisibility)
        main_window.setWindowButtonVisibility(false);
    main_window.loadFile(`src/index.html`);
    // main_window.webContents.openDevTools();
});

process.on('uncaughtException', (err) => {
    console.log(err);
})