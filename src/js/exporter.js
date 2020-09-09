var re_resolution = /resolution[\s=]*(?:(\d+)|{([\d\s]+),([\s\d]+)})/
const DEFAULT_EXPORT_SETTINGS = () => ({
  name: nwPATH.basename(app.project_path),
  /*
	web_autoplay: false,
	scale_mode: 'linear',
	frameless: false,
	minify: true,
	scale: true,
	resizable: false*/
})

class Exporter extends Editor {
  constructor(...args) {
    super(...args)
    let this_ref = this

    if (DragBox.focus("Exporter", true)) return

    this.setupDragbox()
    this.setTitle("Exporter")
    this.removeHistory()
    this.hideMenuButton()

    this.setDefaultSize(211, 294)

    // diplay list of target platforms
    this.platforms = Object.keys(app.engine.export_targets || [])

    this.el_platforms = app.createElement("div", "platforms")
    let el_title1 = app.createElement("p", "title1")
    el_title1.innerHTML = "One-click export"
    this.el_platforms.appendChild(el_title1)

    this.platforms.forEach(function (platform) {
      let el_platform_container = app.createElement("button", [
        "ui-button-rect",
        "platform",
        platform,
      ])

      let el_platform_icon = app.createElement("object")
      el_platform_icon.type = "image/svg+xml"
      el_platform_icon.data =
        "src/icons/" +
        (platform.includes("win")
          ? "win"
          : platform.includes("mac")
            ? "mac"
            : platform.includes("linux")
              ? "linux"
              : platform) +
        ".svg"

      el_platform_container.value = platform
      el_platform_container.addEventListener("click", function (e) {
        this_ref.export(e.target.value)
      })

      const el_platform_label = app.createElement("span", "platform-label")
      el_platform_label.innerHTML = platform.replaceAll("_", " ")

      el_platform_container.appendChild(el_platform_icon)
      el_platform_container.appendChild(el_platform_label)

      this_ref.el_platforms.appendChild(el_platform_container)
    })

    this.appendChild(this.el_platforms)
  }

  // dir : target directory to write bundled files to
  bundle(dir, target_os, cb_done) {
    if (app.engine.bundle) app.engine.bundle(dir, target_os, cb_done)
  }

  static openDistFolder(os) {
    let path = nwPATH.join(app.project_path, "dist", os)
    remote.shell.openItem(path)
    remote.clipboard.writeText(path)
  }

  doneToast(os) {
    process.noAsar = false
    if (this.temp_dir) nwFS.removeSync(this.temp_dir)
    if (this.toast) {
      this.toast.icon = "check-bold"
      this.toast.style = "good"
      this.toast.text =
        "Export done! <a href='#' onclick='Exporter.openDistFolder(\"" +
        os +
        "\");'>View files</a>"
      this.toast.die(8000)

      /*
			app.notify({
				title: 'Export complete!',
				body: `\\( ^o^ )/`,
				onclick: () => {
					Exporter.openDistFolder(os);
				}
			})*/
    }
  }

  errToast(err) {
    process.noAsar = false
    if (this.temp_dir) nwFS.removeSync(this.temp_dir)

    if (this.toast) {
      this.toast.icon = "close"
      this.toast.style = "bad"
      this.toast.text = "Export failed!"
      this.toast.die(8000)

      app.notify({
        title: "Export failed!",
        body: `( -_-")`,
        onclick: () => {
          Exporter.openDistFolder(os)
        },
      })
    }
    console.error(err)
  }

  /*
		darwin
		- darwin-x64
		linux
		- linux-arm64
		- linux-ia32
		- linux-armv7l
		- linux-x64
		mas (mac app store)
		- mas-x64
	*/

  export(target_os) {
    let os_dir = nwPATH.join(app.project_path, "dist", target_os)
    let temp_dir = os_dir

    blanke.toast("Starting export for " + target_os)

    this.toast = blanke.toast("Removing old files", -1)
    this.toast.icon = "dots-horizontal"
    this.toast.style = "wait"

    process.noAsar = true
    nwFS
      .emptyDir(os_dir)
      .catch((err) => {
        this.errToast(err)
        return console.error(err)
      })
      .then(() => {
        // move assets
        if (app.engine.export_assets !== false)
          nwFS.copySync(app.getAssetPath(), nwPATH.join(temp_dir, "assets"))
        let e_assets = app.engine.extra_bundle_assets || {}
        let extra_assets = e_assets[target_os] || e_assets["."] || []

        const eng_path = app.cleanPath(nwPATH.join(app.engine_path, ""))
        const { platform, arch } = app.parsePlatform(target_os)
        const dist_path = app.cleanPath(
          nwPATH.join(app.engine_dist_path(platform, arch), "")
        )

        let cb_done = () => this.doneToast(target_os)

        let cb_err = (err) => {
          app.error(err)
          this.errToast(err)
        }

        new Promise((res, rej) => {
          // check license key
          if (app.engine.export_targets[target_os])
            app.clk().then(res).catch(rej)
          else
            res()
        })
          .then(new Promise((res, rej) => {
            if (app.engine.preBundle) app.engine.preBundle(temp_dir, target_os)
            // create js file
            this.toast.text = `Bundling files`
            this.bundle(temp_dir, target_os, () => res())
          }))
          .then(() => {
            if (!app.engine.export_targets[target_os]) {
              this.doneToast(target_os)
            }
            else {
              this.toast.text = "Building app"

              // split platform and architecture
              const { platform, arch } = app.parsePlatform(target_os)

              if (app.engine.setupBinary)
                return app.downloadEngineDist(platform, arch)
            }
          })
          .then(() => {
            const prom_copy = []

            for (let a of extra_assets) {
              const base_a = a
                .replace("<project_path>", "")
                .replace("<engine_path>", "")
                .replace("<dist_path>", "")

              a = a
                .replace("<project_path>", app.project_path)
                .replace("<engine_path>", eng_path)
                .replace("<dist_path>", dist_path)

              prom_copy.push(
                nwFS.copy(a, app.cleanPath(nwPATH.join(temp_dir, base_a)))
              )
            }

            return Promise.all(prom_copy)
          })
          .then(() =>
            app.engine.setupBinary(
              os_dir,
              temp_dir,
              platform,
              arch,
              cb_done,
              cb_err
            )
          )
          .catch(console.error)
      })
  }
}

document.addEventListener("openProject", function (e) {
  app.removeSearchGroup("Exporter")
  app.addSearchKey({
    key: "Export game",
    group: "Exporter",
    onSelect: function () {
      new Exporter(app)
    },
  })

  let eng_settings = {}
    ; (app.engine.export_settings || []).forEach((s) => {
      for (let prop of s) {
        if (typeof prop == "object" && prop.default)
          eng_settings[s[0]] = prop.default
      }
    })

  app.projSetting(
    "export",
    Object.assign(
      DEFAULT_EXPORT_SETTINGS(),
      eng_settings,
      app.projSetting("export")
    )
  )
})
