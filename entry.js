const elec = require('electron');

elec.app.on('ready', function(){
    let main_window = new elec.BrowserWindow({
        width: 800,
        height: 600,
        frame: false,
        titleBarStyle: "customButtonsOnHover",
        webPreferences: {
            nodeIntegration: true
        }
    })
    main_window.loadFile(`src/index.html`);
    main_window.webContents.openDevTools();
});