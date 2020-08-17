require('v8-compile-cache')
require("dotenv").config()
const unhandled = require("electron-unhandled")
unhandled()

const isDev = require("electron-is-dev")
const { autoUpdater } = require("electron-updater")
const { app: eApp, BrowserWindow, ipcMain } = require("electron")

const WIN_WIDTH = 1366
const WIN_HEIGHT = 768

let update_on_close = false

let main_window
eApp.on("open-file", (e, path) => {
  if (main_window); //main_window.webContents.send('open-file', path);
})
eApp.commandLine.appendSwitch("enable-gpu-rasterization")
eApp.commandLine.appendSwitch("ignore-gpu-blacklist")
eApp.commandLine.appendSwitch("allow-file-access-from-files")
eApp.commandLine.appendSwitch("enable-webgl")

eApp.on("ready", function () {
  const { screen } = require("electron")
  let display = screen.getPrimaryDisplay()

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
  })
  if (main_window.setWindowButtonVisibility)
    main_window.setWindowButtonVisibility(false)

  //main_window.webContents.openDevTools()
  main_window.loadFile("index.html")
  main_window.on("close", (e) => {
    if (!update_on_close) {
      main_window.webContents.send("close", e)
      e.preventDefault()
    } else {
      autoUpdater.quitAndInstall()
    }
  })

  main_window.webContents.on("new-window", function (e, url) {
    e.preventDefault()
    if (url.length > 1) require("electron").shell.openExternal(url)
  })

  ipcMain.on("openDevTools", (e) => main_window.webContents.openDevTools())
  ipcMain.on("showWindow", (e) => main_window.show())

  ipcMain.on("checkForUpdates", (e) => {
    autoUpdater
      .checkForUpdates()
      .catch((e) => console.log(`Update Error: ${e}`))
  })
  ipcMain.on("installUpdate", () => {
    update_on_close = true
    main_window.close()
  })

  autoUpdater.autoInstallOnAppQuit = false
  autoUpdater.on("update-available", (e) =>
    main_window.webContents.send("update-available", e)
  )
  autoUpdater.on("update-downloaded", (e) =>
    main_window.webContents.send("update-downloaded", e)
  )
  autoUpdater.on("update-not-available", (e) =>
    main_window.webContents.send("update-not-available", e)
  )
  autoUpdater.on("download-progress", (e) =>
    main_window.webContents.send("download-progress", e)
  )

  autoUpdater.on("error", (err) => {
    console.error(err)
  })
})

eApp.commandLine.appendSwitch("ignore-gpu-blacklist")

process.on("uncaughtException", (err) => {
  console.log(err)
})
