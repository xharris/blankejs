const nwMD = require("markdown-it")()

let plugin_md_list = []
let getDocPath = () => nwPATH.join(app.engine_path, "docs")

class Docview extends Editor {
  constructor(...args) {
    super(...args)

    if (DragBox.focus("Docs", true)) return

    this.setupDragbox()
    this.setTitle("Docs")
    this.removeHistory()
    this.hideMenuButton()

    this.setDefaultSize(530, 410)

    var this_ref = this

    this.doc_data = {}
    this.doc_container = app.createElement("div", "doc-container")
    this.doc_body_container = app.createElement("div", [
      "doc-body-container",
      "markdown",
    ])
    this.appendChild(this.doc_container)
    this.appendChild(this.doc_body_container)

    let doc_path = getDocPath()
    nwFS.readFile(nwPATH.join(doc_path, "docs.json"), "utf-8", (err, data) => {
      if (!err) {
        this.doc_sections = JSON.parse(data)

        let categories = Object.keys(this.doc_sections)
        /*.sort((a, b) =>
          a < b ? -1 : 1
        )*/

        this.doc_sections.Plugins = plugin_md_list
        categories.push("Plugins")

        // put the divs together
        for (let category of categories) {
          // CATEGORY
          let el_section = app.createElement("div", "section")
          let el_header = app.createElement("p", "header")
          let el_body = app.createElement("div", ["body", "hidden"])

          let num_sections = Object.keys(this.doc_sections[category]).length

          for (let subsection in this.doc_sections[category]) {
            let info = this.doc_sections[category][subsection]

            let el_subsection = app.createElement("div", "subsection")
            let el_subheader = app.createElement("p", "subheader")
            let el_doc_body = this.doc_body_container
            let el_doc = this.doc_container

            let md_path = nwPATH.join(doc_path, info.file)
            el_subsection._tags = info.tags
            el_subheader.innerHTML = info.title

            let reveal = () => {
              // get .md content
              nwFS.readFile(md_path, "utf-8")
                .then(data => {
                  this.setSubtitle(
                    " - " + (num_sections > 1 ? info.title : category)
                  )

                  // el_doc_body.innerHTML = markdown.toHTML(data);

                  el_doc_body.innerHTML = nwMD.render(data)

                  if (el_doc_body.innerHTML.trim() == "")
                    el_doc_body.innerHTML =
                      "No information on this topic found"

                  for (let c = 0; c < el_doc.children.length; c++) {
                    el_doc.children[c].classList.remove("selected")
                  }
                  document
                    .querySelectorAll(".subsection")
                    .forEach(sec => sec.classList.remove("selected"))

                  if (num_sections > 1) {
                    el_subsection.classList.add("selected")
                  }
                  if (num_sections == 1) el_section.classList.add("selected")

                  // syntax highlighting
                  document.querySelectorAll("code").forEach(block => {
                    block.className = app.engine.language || ""
                    hljs.highlightBlock(block)
                  })
                  // links
                  document.querySelectorAll("a").forEach(block => {
                    block.title = block.href
                  })
                  app.sanitizeURLs()
                })
                .catch(console.error)
            }

            if (num_sections == 1) {
              // ONLY 1 SUBSECTION
              el_section.classList.add("single")
              el_section.addEventListener("click", reveal)
            } else {
              // SUBSECTION
              el_subsection.appendChild(el_subheader)
              el_section.appendChild(el_subsection)
              el_subheader.addEventListener("click", reveal)
            }
          }

          el_header.innerHTML = category
          el_header.title = category

          el_section.prepend(el_header)

          this.doc_container.appendChild(el_section)
        }
      }
    })
  }

  static addPlugin(title, file) {
    let found = false
    file = nwPATH.relative(getDocPath(), file)

    plugin_md_list.forEach(obj => {
      if (obj.title == title) {
        obj.file = file
        found = true
      } else if (obj.file == file) {
        obj.title = title
        found = true
      }
    })
    if (!found) plugin_md_list.push({ title: title, file: file })

    plugin_md_list = plugin_md_list.sort((a, b) =>
      a.title < b.title ? -1 : 1
    )
  }

  static removePlugin(file) {
    file = nwPATH.relative(getDocPath(), file)
    plugin_md_list = plugin_md_list.filter(p => p.file != file)
  }
}
