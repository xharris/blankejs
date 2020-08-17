// TODO open editor and another file, turn off splitting, go to image editor (resize not called for canvas resizing)
// TODO if user attempts to rename before the first save (image is image1.png), save then rename

const EDITOR_TITLE = "Image Editor"
const DEFAULT_IMAGE_SETTINGS = {
  frame_size: [256, 256],
  frames: 1,
  position: [0, 0],
  spacing: 0,
  onion_alpha: 0.3,
}
const MARGIN_LEFT = 5
const MARGIN_TOP = 40
const HISTORY_TIMER = 2000
const HISTORY_MAX = 30
const TOOLS = ["pencil", "eraser", "eyedrop"]
const TOOL_INSTR = {
  pencil: "LeftClick = draw, RightClick = erase",
  eraser: "LeftClick = erase",
  eyedrop: "LeftClick = add color to pallette"
}
let colors = [
  "f44336",
  "E91E63",
  "9C27B0",
  "673AB7",
  "3F51B5",
  "2196F3",
  "03A9F4",
  "00BCD4",
  "009688",
  "4CAF50",
  "8BC34A",
  "CDDC39",
  "FFEB3B",
  "FFC107",
  "FF9800",
  "FF5722",
  "795548",
  "9E9E9E",
  "607D8B",
  "FFFFFF",
  "000000",
]
let img_editors = []
let bg_colors = [0xeeeeee, 0xbfbfbf]

let rgbToHex = color => {
  let hex = c => {
    var h = Number(c).toString(16)
    if (h.length < 2) {
      h = "0" + h
    }
    return h
  }
  return "0x" + hex(color.r) + hex(color.g) + hex(color.b)
}

class ImageEditor extends Editor {
  constructor(file) {
    super()
    this.setupFibWindow()
    this.file = null
    this.img_settings = {}
    this.curr_color = 0x000000
    this.cursor = [0, 0]
    this.img_left = 0
    this.img_top = 0
    this.img_width = DEFAULT_IMAGE_SETTINGS.frame_size[0]
    this.img_height = DEFAULT_IMAGE_SETTINGS.frame_size[1]
    this.clear_rtx = 0
    this.hover_frame = 0
    this.hover_frame_pos = [0, 0]
    this.changed = false
    this.not_saved = false
    this.history_tex = []
    this.history_cd = HISTORY_TIMER
    this.last_edited_frame = -1
    // create elements
    this.el_top_right_container = app.createElement(
      "div",
      "top-right-container"
    )
    let form_options = [
      ["image", "select", { label: false }],
      ["image settings", true],
      ["position", "number", { min: 0, inputs: 2, separator: "x" }],
      ["spacing", "number"],
      ["frame_size", "number", { inputs: 2, separator: "x", min: 1 }],
      ["frames", "number", { min: 1 }],
      ["showPreview", "checkbox", { default: true }],
      ["showBackgroundGrid", "checkbox", { default: true }],
      [
        "animSpeed",
        "number",
        { min: 0, default: 0.5, step: 0.1, label: "animation speed" },
      ],
      ["onion_alpha", "number", { min: 0, max: 1, step: 0.05 }],
      ["tools"],
      ...TOOLS.map(t => [t, "icon-button"]),
      ["tool settings", false],
      [
        "tool.shape",
        "select",
        { choices: ["rect", "circle", "line"], label: "shape" },
      ],
      [
        "tool.alpha",
        "number",
        { min: 0, max: 255, default: 255, label: "alpha" },
      ],
      ["tool.fill", "checkbox", { default: true, label: "fill" }],
      ["tool.thickness", "number", { min: 0, default: 1, label: "thickness" }],
      [
        "tool.size",
        "number",
        { min: 1, default: [1, 1], inputs: 2, separator: "x", label: "size" },
      ],
      ["tool.radius", "number", { min: 1, default: 1, label: "radius" }],
      [
        "tool.angle",
        "number",
        { min: 0, max: 360, default: 0, label: "angle" },
      ],
      ["tool.length", "number", { min: 1, default: 1, label: "length" }],
    ]
    this.el_image_form = new BlankeForm(form_options)
    this.el_sidebar = app.createElement("div", "sidebar")
    this.el_colors = app.createElement("div", "color-container")
    //this.el_layers = new BlankeListView({object_type:"layer"});
    this.pixi = new BlankePixi()
    this.renderer = PIXI.autoDetectRenderer()

    this.img_container = new PIXI.Container()
    this.crosshair = new PIXI.Graphics()
    // image editing-related

    this.edit_container = new PIXI.Container() // all the stuff that will be saved to image file
    this.render_img = this.edit_container
    this.temp_rtx_used = false
    this.img_background = new PIXI.Graphics()
    this.img_edits = new PIXI.Graphics()
    this.img_rtx = PIXI.RenderTexture.create(this.width, this.height)
    this.img_rtx_temp = PIXI.RenderTexture.create(this.width, this.height)
    this.img_sprite = new PIXI.Sprite(this.img_rtx)
    this.img_erase = new PIXI.Graphics()
    this.img_erase.blendMode = 22
    this.edit_prvw_graphic = new PIXI.Graphics()
    this.edit_prvw_rtx = PIXI.RenderTexture.create(this.width, this.height)
    this.edit_prvw = new PIXI.Sprite(this.edit_prvw_rtx)
    this.img_onion = new PIXI.Sprite(PIXI.Texture.EMPTY)
    this.img_onion.alpha = DEFAULT_IMAGE_SETTINGS.onion_alpha

    this.anim_container = new PIXI.Container()

    // masks
    this.img_mask = new PIXI.Graphics()
    this.edit_container.mask = this.img_mask
    this.edit_prvw.mask = this.img_mask

    this.edit_container.addChild(
      this.img_mask,
      this.img_sprite,
      this.img_edits,
      this.img_erase
    )
    this.img_container.addChild(
      this.anim_container,
      this.img_background,
      this.img_onion,
      this.edit_container,
      this.crosshair,
      this.edit_prvw
    )
    this.pixi.stage.addChild(this.img_container)

    // setup el_image_form
    form_options.forEach(s => {
      if (s.length > 1) {
        this.el_image_form.onChange(s[0], val => {
          if (s[0] != "image") this.img_settings[s[0]] = val
          if (s[0] == "image") this.img_settings[s[0]] = app.shortenAsset(val)
          this.drawBackground()
          this.drawEditPreview()
          this.setTool(s[0])
          if (s[0] == "size") this.resize = true
          if (s[0] == "animSpeed" && this.anim) {
            this.positionAnimationPreview()
            this.anim.animationSpeed = val
            this.anim.play()
          }
          if (!s[0].includes("tool")) this.refreshAnimation()
          if (s[0] == "onion_alpha") {
            this.img_onion.alpha = val
          }
          this.previewCursor()
        })
      }
    })
    this.setTool(TOOLS[0])

    this.container.fib_content.addEventListener('mouseleave', e => {
      this.stopPreviewCursor()
    })

    // setup el_file_select
    document.addEventListener("fileChange", e => {
      if (app.findAssetType(e.detail.file) == "image") this.refreshImageList()
    })
    this.refreshImageList()
    this.el_image_form.onChange("image", value => {
      this.openFile(value)
    })

    // setup pixi
    //this.img_container.sortChildren();
    this.pixi.stage.interactive = true
    this.pixi.view.addEventListener("contextmenu", e => {
      e.preventDefault()
    })
    this.addCallback("onResize", () => {
      this.pixi.resize()
    })
    this.pixi.on("cameraChange", e => {
      this.img_container.position.set(e.x, e.y)
      this.positionAnimationPreview()
      this.switch_rtx = false
    })
    let toolActive = btn => {
      let tool = this.curr_tool

      if (tool == "pencil" && btn == 0)
        this.drawPoint(this.curr_color)
      if ((tool == "eraser" && btn == 0) || (tool == "pencil" && btn == 2))
        this.erase()
      if (tool == "eyedrop" && btn == 0)
        this.curr_color = rgbToHex(this.getPoint(this.cursor[0], this.cursor[1]))
      this.drawCrosshair()
    }
    this.pixi.on("mouseMove", (e, info) => {
      let { mx, my, btn } = info
      this.setCursorPosition(Math.floor(mx), Math.floor(my))
      this.hover_frame_pos[0] =
        this.cursor[0] - (this.cursor[0] % this.img_settings.frame_size[0])
      this.hover_frame = Math.floor(
        this.cursor[0] / this.img_settings.frame_size[0]
      )
      this.updateOnion()

      this.drawCrosshair()
      toolActive(btn)
    })

    this.pixi.on("mouseDown", (e, info) => {
      let { mx, my, btn } = info
      this.setCursorPosition(Math.floor(mx), Math.floor(my))
      toolActive(btn)
    })
    this.pixi.on("mouseUp", (e, info) => {
      this.img_erase.clear()
    })
    this.pixi.setCameraPosition(MARGIN_LEFT, MARGIN_TOP)
    this.save_key_up = true
    this.undo_key_up = true
    this.pixi.on("keyDown", (e, info) => {
      if (e.ctrlKey && e.key == "s" && this.save_key_up) {
        this.save()
        this.save_key_up = false
      }
      if (e.ctrlKey && e.key == "z" && this.undo_key_up) {
        e.preventDefault()
        this.undo()
        this.undo_key_up = false
      }
    })
    this.pixi.on("keyUp", (e, info) => {
      if (e.key == "s") this.save_key_up = true
      if (e.key == "z") this.undo_key_up = true
    })

    this.img_ready = false
    this.pixi.ticker.add(() => {
      if (this.img_ready)
        this.renderImageTexture()
    })
    this.pixi.hide_mouse = true
    // [gl.FUNC_REVERSE_SUBTRACT, gl.FUNC_ADD]  -- OR -- [gl.ZERO, gl.ONE_MINUS_SRC_ALPHA, gl.ZERO, gl.ONE_MINUS_SRC_ALPHA]

    // setup el_colors
    const addColor = c => {
      let el_color = app.createElement("div", "color")
      c = c.replace("0x", "")
      el_color.style.backgroundColor = `#${c}`
      el_color.title = `#${c}`
      el_color.value = parseInt(`0x${c}`)
      el_color.addEventListener("click", e => {
        this.curr_color = e.target.value
        this.previewCursor()
      })
      el_color.addEventListener("contextmenu", e => {
        app.contextMenu(e.x, e.y, [
          {
            label: "edit",
            click: () => {
              blanke.askColor(`#${c}`, e => {
                el_color.style.backgroundColor = e.target.value
                el_color.title = e.target.value
                el_color.value = e.target.value
              })
            },
          },
          {
            label: "delete",
            click: () => {
              blanke.destroyElement(el_color)
            },
          },
        ])
      })
      this.el_colors.appendChild(el_color)
    }
    colors.forEach(c => addColor(c))
    let el_add_color = app.createElement("div", "add-color")
    el_add_color.innerHTML = "+"
    el_add_color.addEventListener("click", e => {
      addColor(this.curr_color.toString(16))
    })
    this.el_colors.insertBefore(el_add_color, this.el_colors.firstChild)

    // add elements to Editor
    this.el_top_right_container.appendChild(this.el_image_form.container)
    this.el_sidebar.appendChild(this.el_colors)
    //this.el_sidebar.appendChild(this.el_layers);
    this.appendChild(this.el_top_right_container)
    this.appendChild(this.el_sidebar)
    this.appendChild(this.pixi.view)
    this.appendBackground(this.pixi.view)

    this.setTitle(EDITOR_TITLE)
    this.setOnClick(() => {
      ImageEditor.openImage(this.file)
    })

    this.setupMenu({
      close: true,
      rename: () => {
        this.setTitle(nwPATH.basename(this.file))
      },
      delete: () => {
        this.close(true)
      },
    })

    if (file && file != EDITOR_TITLE) this.openFile(file)
    img_editors.push(this)
  }
  onClose() {
    img_editors = img_editors.filter(
      e => e.container.guid != this.container.guid
    )
    img_editors.forEach(e => {
      e.refreshImageList()
    })
  }
  onBeforeClose(res, rej) {
    if (this.not_saved) {
      blanke.showModal(
        "<label>'" +
        nwPATH.basename(this.file) +
        "' has unsaved changes! Save before closing?</label>",
        {
          yes: () => { this.save(); res() },
          no: () => { res() },
          cancel: () => { }
        }
      )
    } else {
      res()
    }
  }
  openFile(path) {
    this.file = path
    let fname = app.shortenAsset(path)
    this.setTitle(nwPATH.basename(path))
    // project settings
    if (!app.projSetting("imageeditor")) app.projSetting("imageeditor", {})
    let image_edit_settings = app.projSetting("imageeditor")

    const setupForm = () => {
      image_edit_settings.image = app.shortenAsset(image_edit_settings.image)
      app.saveSettings()
      image_edit_settings.image = app.lengthenAsset(image_edit_settings.image)
      this.img_ready = true
      let [cx, cy] = this.getCenter()
      this.pixi.setCameraPosition(
        cx - this.img_width / 2,
        cy - this.img_height / 2
      )
      this.el_image_form.useValues(this.img_settings)
      this.checkFormVisibility()
      this.drawBackground()

      // resize render textures to image size
      const best_width = Math.max(this.width, this.img_width)
      const best_height = Math.max(this.height, this.img_height)
      if (this.img_rtx.width != best_width || this.img_rtx.height != best_height) {
        this.img_rtx.resize(best_width, best_height)
        this.img_rtx_temp.resize(best_width, best_height)
        this.edit_prvw_rtx.resize(best_width, best_height)
      }

      if (nwFS.pathExistsSync(path)) {
        this.pixi.loadRes(path, (loader, res) => {
          var initial_spr = new PIXI.Sprite(res[path].texture)
          this.render(initial_spr, true)
        })
      }
      this.clearHistory()
      this.refreshAnimation()
      this.storeUndo(true)
    }

    let new_file = false
    if (!image_edit_settings[fname]) {
      image_edit_settings[fname] = {}
      new_file = true
    }
    ifndef_obj(image_edit_settings[fname], DEFAULT_IMAGE_SETTINGS)
    this.img_settings = image_edit_settings[fname]

    this.img_ready = false
    if (new_file && nwFS.pathExistsSync(path)) {
      let img = new Image()
      img.onload = () => {
        this.img_settings.frame_size = [img.width, img.height]
        setupForm()
      }
      img.src = "file://" + path
    } else setupForm()
  }
  setCursorPosition(x, y) {
    if (!this.previewing_cursor)
      this.cursor = [x, y]
  }
  previewCursor() {
    const set = this.img_settings
    // put mouse in center of last frame edited to show changes to settings
    if (this.last_edited_frame === -1)
      this.last_edited_frame = 0
    const curx = this.last_edited_frame * (set.frame_size[0] + set.spacing) + (set.frame_size[0] / 2)
    const cury = set.frame_size[1] / 2

    this.previewing_cursor = true
    this.cursor = [curx, cury]
    this.drawCrosshair()
  }
  stopPreviewCursor() {
    this.previewing_cursor = false
  }
  drawCrosshair() {
    let cross = this.crosshair
    cross.clear()
    cross.lineStyle(Math.max(1 / this.pixi.zoom, 1), this.curr_color, 0.3)
    const curx = this.cursor[0]
    const cury = this.cursor[1]

    // vertical
    cross.moveTo(curx + 0.5, this.pixi.top)
    cross.lineTo(curx + 0.5, this.pixi.bottom)
    // horizontal
    cross.moveTo(this.pixi.left, cury + 0.5)
    cross.lineTo(this.pixi.right, cury + 0.5)

    this.drawEditPreview()
    this.refreshHelpText()
  }
  drawEditPreview() {
    // update draw preview
    if (this.curr_tool == "pencil") {
      this.edit_prvw_graphic.visible = true
      this.performDrawOps(
        this.edit_prvw_graphic,
        this.curr_color,
        this.el_image_form.getValue("tool.alpha")
      )
    } else if (this.curr_tool == "eraser") {
      this.edit_prvw_graphic.visible = true
      this.performDrawOps(this.edit_prvw_graphic, 0x000000, 0.5)
    } else {
      this.edit_prvw_graphic.visible = false
    }
  }
  updateOnion() {
    if (
      this.anim &&
      this.hover_frame > 0 &&
      this.hover_frame < this.anim.textures.length &&
      this.anim.textures[this.hover_frame - 1]
    )
      this.img_onion.texture = this.anim.textures[this.hover_frame - 1]
    else this.img_onion.texture = PIXI.Texture.EMPTY
    this.img_onion.position.set(...this.hover_frame_pos)
  }
  refreshImageList() {
    let sel_str = `<option class="placeholder" value="" disabled ${
      this.file ? "" : "selected"
      }>Select an image</option>`
    this.el_image_form.getInput("image").innerHTML = sel_str
    app.getAssets("image", files => {
      if (!files.some(f => f == this.file)) files.push(this.file)
      files.forEach(f => {
        if (!img_editors.some(e => e.file == f && e.file != this.file)) {
          var img_path = nwPATH.basename(f)
          sel_str += `<option value="${f}" ${
            this.file == f ? "selected" : ""
            }>${img_path}</option>`
        }
      })
      this.el_image_form.getInput("image").innerHTML = sel_str
      this.el_image_form.useValues(this.img_settings)
    })
  }
  refreshHelpText() {
    this.pixi.setInfoText(`x ${this.cursor[0]} y ${this.cursor[1]} (${this.img_width}px x ${this.img_height}px)`)
    this.pixi.setHelpText(TOOL_INSTR[this.curr_tool] || '')
  }
  drawBackground() {
    let bg = this.img_background
    let set = this.img_settings
    ifndef_obj(this.img_settings, DEFAULT_IMAGE_SETTINGS)
    bg.clear()
    let white_tile = true
    const t_size = 20

    this.img_left = set.position[0]
    this.img_top = set.position[1]
    this.img_width =
      (set.frame_size[0] + set.spacing) * set.frames - set.spacing
    this.img_height = set.frame_size[1]

    this.pixi.setCameraBounds(
      0,
      0,
      this.pixi.width - this.img_width,
      this.pixi.height - this.img_height
    )

    // draw transparency tiles
    if (this.el_image_form.getValue("showBackgroundGrid")) {
      for (let x = 0; x < this.img_width; x += t_size) {
        white_tile = (x / t_size) % 2 == 0 ? true : false
        for (let y = 0; y < this.img_height; y += t_size) {
          bg.beginFill(white_tile ? bg_colors[0] : bg_colors[1])
          bg.drawRect(
            x,
            y,
            x + t_size > this.img_width ? this.img_width - x : t_size,
            y + t_size > this.img_height ? this.img_height - y : t_size
          )
          bg.endFill()
          white_tile = !white_tile
        }
      }
    }
    // draw frame rects
    for (let x = this.img_left; x < this.img_width; x += set.frame_size[0] + set.spacing) {
      bg.lineStyle(1, app.getThemeColor("ide-accent"), 0.5)
      bg.drawRect(x, this.img_top, set.frame_size[0], set.frame_size[1])
    }
    // update mask
    let mask = this.img_mask
    mask.clear()
    mask.beginFill(0xffffff)
    mask.drawRect(0, 0, this.img_width, this.img_height)
    mask.endFill()
    if (this.resize) {
      // resize rendertexture
      this.img_rtx_temp.resize(this.img_width, this.img_height)
    }
  }
  setTool(name) {
    if (TOOLS.includes(name)) {
      this.curr_tool = name
      this.refreshHelpText()
      this.el_image_form.getInput(name).classList.add("selected")
      TOOLS.forEach(t => {
        if (t != name)
          this.el_image_form.getInput(t).classList.remove("selected")
      })
      this.drawEditPreview()
    }
    this.checkFormVisibility()
  }
  checkFormVisibility() {
    let form = this.el_image_form
    form.hideInput("tool.radius")
    form.hideInput("tool.thickness")
    form.hideInput("tool.radius")
    form.hideInput("tool.size")
    form.hideInput("tool.length")

    form.showInput("tool.fill")

    let shape = form.getValue("tool.shape")
    if (shape == "rect") {
      form.showInput("tool.size")

      if (form.getValue("tool.fill")) form.hideInput("tool.thickness")
      else form.showInput("tool.thickness")
    }
    if (shape == "circle") form.showInput("tool.radius")
    if (shape == "line") {
      form.showInput("tool.length")
      form.showInput("tool.thickness")
      form.hideInput("tool.fill")
    }
  }
  _refreshAnimation() {
    if (this.changed || this.render_anim) {
      this.render_anim = false
      let tex_frames = []
      let set = this.img_settings

      const y = this.img_top
      for (
        let x = this.img_left;
        x < this.img_width;
        x += set.frame_size[0] + set.spacing
      ) {
        let new_tex = this.img_rtx.clone()
        const [fw, fh] = set.frame_size

        new_tex.frame = new PIXI.Rectangle(
          x,
          y,
          x + fw > new_tex.width ? fw - ((x + fw) % new_tex.width) : fw,
          y + fh > new_tex.height ? fh - ((y + fh) % new_tex.height) : fh,
        )
        tex_frames.push(new_tex)
      }
      if (this.anim) this.anim.destroy()
      this.anim = new PIXI.AnimatedSprite(tex_frames)
      this.anim.animationSpeed = this.el_image_form.getValue("animSpeed")
      this.anim.play()
      this.anim_container.addChild(this.anim)
      this.anim_container.y = this.img_height
    }
    this.positionAnimationPreview()
  }
  refreshAnimation() {
    this.render_anim = true
  }
  positionAnimationPreview() {
    this.anim_container.position.set(
      -this.pixi.camera[0] / Math.max(1, this.pixi.zoom),
      (-this.pixi.camera[1] + 34) / Math.max(1, this.pixi.zoom)
    )
    this.anim_container.visible = this.el_image_form.getValue("showPreview")
  }
  getPoint(x, y) {
    let pixels = this.pixi.renderer.extract.pixels(this.edit_container)
    let i = (y * this.edit_container.width + x) * 4
    return {
      r: pixels[i],
      g: pixels[i + 1],
      b: pixels[i + 2],
      a: pixels[i + 3],
    }
  }
  performDrawOps(obj, color, alpha, overrides) {
    let tset = (v, i) => {
      if (overrides && overrides[v])
        return i != null ? overrides[v][i] : overrides[v]
      else return this.el_image_form.getValue(v, i)
    }
    let x = this.cursor[0],
      y = this.cursor[1]
    let shape = tset("tool.shape")
    let fill = tset("tool.fill")
    if (!alpha) alpha = tset("tool.alpha")
    let w = tset("tool.size", 0)
    let h = tset("tool.size", 1)
    let angle = tset("tool.angle")

    obj.clear()
    if (fill && shape != "line") obj.beginFill(color, alpha)
    else {
      let alignment = 0
      if (shape == "line") alignment = 0.5
      obj.lineStyle(tset("tool.thickness"), color, alpha, alignment)
    }
    if (shape == "rect") {
      obj.drawRect(0, 0, w, h)
      obj.angle = angle
    }
    if (shape == "circle") {
      obj.drawCircle(0, 0, tset("tool.radius"))
      obj.angle = 0
    }
    if (shape == "line") {
      let dist = tset("tool.length")
      obj.moveTo(0, 0)
      obj.lineTo(dist, 0)
      obj.angle = angle
    }

    if (fill) obj.endFill()

    if (shape == "rect")
      obj.pivot.set(Math.floor(w * 0.5), Math.floor(h * 0.5))
    else obj.pivot.set(0, 0)
    obj.position.set(x, y)
  }
  drawPoint(color, alpha) {
    this.performDrawOps(this.img_edits, color, alpha)
    this.storeUndo()
    this.refreshAnimation()
  }
  erase() {
    this.performDrawOps(this.img_erase, 0xffffff, 1.0)
    this.storeUndo()
    this.refreshAnimation()
  }
  render(img, clear) {
    this.rendered_image = false
    this.render_img = img
    if (clear) this.clear_rtx = 2
  }
  renderImageTexture() {
    let temp = this.img_rtx
    this.img_rtx = this.img_rtx_temp
    this.img_rtx_temp = temp

    this.img_sprite.texture = this.img_rtx
    this.pixi.renderer.render(
      this.render_img,
      this.img_rtx_temp,
      this.clear_rtx > 0
    )
    // reset stuff
    if (!this.rendered_image) this.rendered_image = true
    else this.render_img = this.edit_container
    this.img_edits.clear()
    if (this.clear_rtx > 0) this.clear_rtx--
    //this.img_erase.clear();

    this.pixi.renderer.render(this.edit_prvw_graphic, this.edit_prvw_rtx, true)

    this.history_cd -= this.pixi.ticker.deltaMS
    if (this.changed) {
      this.changed = false
      if (this.history_tex.length >= HISTORY_MAX) this.history_tex.shift()
      if (this.history_cd <= 0) {
        this.history_cd = HISTORY_TIMER
        let rtx = PIXI.RenderTexture.create(this.img_width, this.img_height)
        let spr = new PIXI.Sprite(rtx)
        this.pixi.renderer.render(this.render_img, rtx, true)
        this.history_tex.push(spr)
      }
    }

    this._refreshAnimation()
  }
  clearHistory() {
    this.history_tex = []
    this.history_cd = HISTORY_TIMER
  }
  storeUndo(now) {
    if (now) this.history_cd = 0
    else this.addAsterisk()
    this.changed = true
    this.last_edited_frame = this.hover_frame
  }
  undo() {
    let spr = this.history_tex.pop()
    if (spr) this.render(spr, true)
  }
  save() {
    if (this.file) {
      let rtx = PIXI.RenderTexture.create(this.img_width, this.img_height)
      this.pixi.renderer.render(this.edit_container, rtx)
      let img = this.pixi.renderer.plugins.extract.image(rtx)
      img.onload = () => {
        let buf = Buffer.from(
          img.src.replace(/^data:image\/\w+;base64,/, ""),
          "base64"
        )
        nwFS.writeFile(this.file, buf)
        this.removeAsterisk()
      }
    }
  }
  addAsterisk() {
    this.not_saved = true
    this.setSubtitle("*")
  }

  removeAsterisk() {
    this.not_saved = false
    this.setSubtitle()
  }

  static openImage(f) {
    if (!FibWindow.focus(nwPATH.basename(f || EDITOR_TITLE))) new ImageEditor(f)
  }
}

document.addEventListener("openProject", e => {
  app.addSearchKey({
    key: "Open image editor",
    onSelect: () => {
      app.getNewAssetPath("image", (path, name) => {
        ImageEditor.openImage(path)
      })
    },
  })
})

document.addEventListener("themeChanged", e => {
  img_editors.forEach(e => {
    e.drawBackground()
  })
})
