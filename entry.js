require("update-electron-app")();

const { app: eApp, BrowserWindow, ipcMain } = require("electron");
const path = require("path");

const WIN_WIDTH = 1000;
const WIN_HEIGHT = 700;

let main_window;
eApp.on("open-file", (e, path) => {
  if (main_window); //main_window.webContents.send('open-file', path);
});
eApp.commandLine.appendSwitch("enable-gpu-rasterization", "true");
eApp.on("ready", function () {
  const { screen } = require("electron");
  let display = screen.getPrimaryDisplay();

  main_window = new BrowserWindow({
    x: display.bounds.x + (display.bounds.width - WIN_WIDTH) / 2,
    y: display.bounds.y + (display.bounds.height - WIN_HEIGHT) / 2,
    width: WIN_WIDTH,
    height: WIN_HEIGHT,
    frame: false,
    titleBarStyle: "hidden",
    backgroundColor: "#fff",
    webPreferences: {
      nodeIntegration: true,
      webgl: true,
      webSecurity: false,
      experimentalFeatures: true,
      experimentalCanvasFeatures: true,
    },
    show: false,
  });
  if (main_window.setWindowButtonVisibility)
    main_window.setWindowButtonVisibility(false);

  // main_window.webContents.openDevTools();
  main_window.loadFile(path.join(__dirname, "src", "index.html"));
  main_window.on("close", e => {
    main_window.webContents.send("close", e);
    e.preventDefault();
  });

  main_window.webContents.on("new-window", function (e, url) {
    e.preventDefault();
    if (url.length > 1) require("electron").shell.openExternal(url);
  });

  ipcMain.on("openDevTools", e => main_window.webContents.openDevTools());
  ipcMain.on("showWindow", e => main_window.show());
});

eApp.commandLine.appendSwitch("ignore-gpu-blacklist");

process.on("uncaughtException", err => {
  console.log(err);
});
