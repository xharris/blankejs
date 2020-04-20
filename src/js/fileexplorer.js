const $ = require("jquery");
require("jquery.fancytree");
require("jquery.fancytree/dist/modules/jquery.fancytree.persist");
require("jquery.fancytree/dist/modules/jquery.fancytree.dnd5");

const ROOT_KEY = "root_/"

const fancytree = () => $.ui.fancytree.getTree("#file-explorer");

const getKey = path => {
  const ret = app.cleanPath("/" + nwPATH.relative(app.cleanPath(app.project_path), path || app.project_path));
  if (ret === "/") return ROOT_KEY
  return ret;
}

const getPath = key => nwPATH.join(app.project_path, key.replace(ROOT_KEY, "/"))

const ignores = [/\/config\.json/, /\/dist(\/.*)?/];

const getFolderData = async (folder_path) => new Promise((res, rej) => {
  const path_key = getKey(folder_path);
  const files = nwFS.readdirSync(folder_path, { withFileTypes: true })
  if (!files) return rej('cant read dir', folder_path);
  else {
    if (ignores.some(i => path_key.match(i))) return //console.log('ignoring folder ' + folder_path);

    const children = [];
    files.forEach(f => {
      const child_path = nwPATH.join(folder_path, f.name)
      const child_key = getKey(child_path)
      if (ignores.some(i => child_key.match(i))) return //console.log('ignoring file ' + child_path);

      // console.log(f.name)
      if (f.isDirectory())
        children.push({ title: nwPATH.basename(f.name), key: child_key, folder: true, lazy: true })
      else
        children.push({ title: nwPATH.basename(f.name), key: child_key })
    })
    return res(children)
  }
}).catch(e => { console.log(e) })

const getFileData = async (file_path) => new Promise((res, rej) => {
  const path_key = getKey(file_path);
  if (ignores.some(i => path_key.match(i))) return rej();

  const stat = nwFS.lstatSync(file_path);
  if (stat.isDirectory()) {
    return res({
      title: nwPATH.basename(path_key),
      key: path_key,
      folder: true,
      lazy: true
    })
  }
  return res({
    title: nwPATH.basename(path_key),
    key: path_key,
  })
})

class FileExplorer {
  static fileChanged(path) {

    // file changes
    // iterate parent children
    // if old child file doesn't exist
    // if new child file path exists, rename the child title
    // else, remove the child
    const path_key = getKey(path);
    const parent_path = nwPATH.dirname(path);
    const parent_key = getKey(parent_path);

    const parent_node = fancytree().getNodeByKey(parent_key);
    if (parent_node && parent_node.children) {
      // iterate parent children
      parent_node.children.forEach(child_node => {
        nwFS.pathExists(getPath(child_node.key), (err, exists) => {
          if (err || !exists) {
            // if old child file doesn't exist
            nwFS.pathExists(path, (err2, exists2) => {
              if (!err2 && exists2) {
                // if new child file path exists, rename the child title
                child_node.setTitle(nwPATH.basename(path))
              } else {
                // else, remove the child
                child_node.remove()
              }
            })
          }
        })
      })
      // add new child?
      nwFS.pathExists(path, (err, exists) => {
        if (err || !exists) return;

        const child_node = fancytree().getNodeByKey(path_key)
        if (!child_node) {
          getFileData(path).then(child_data => {
            parent_node.addChildren([child_data])
          })
        }
      })
    }
  }

  static show() {
    // const walker = nwWALK.walk(app.project_path);
    // walker.on("file");
    $(function () {
      $("#file-explorer").fancytree({
        extensions: ["persist", "dnd5"],
        treeId: "/",
        selectMode: 1,
        clickFolderMode: 3,
        activeVisible: true,
        source: async (e, data) => await getFolderData(nwPATH.join(app.project_path)),
        lazyLoad: (e, data) => {
          const dfd = $.Deferred();
          data.result = dfd.promise();
          getFolderData(nwPATH.join(app.project_path, data.node.key)).then(data => {
            dfd.resolve(data)
          })
        },
        click: (e, data) => {
          if (!data.node.folder) {
            const full_path = getPath(data.node.key);
            const asset_type = app.findAssetType(full_path);
            if (asset_type === "script") {
              Code.openScript(full_path);
            }
            if (asset_type === "image") {
              ImageEditor.openImage(full_path);
            }
            if (asset_type === "map") {
              SceneEditor.openScene(full_path)
            }
          }
        },
        //wide: {},
        persist: {
          cookiePrefix: `fancytree-${app.project_path}-`,
          expandLazy: true,
          overrideSource: true,
          store: "auto"
        },
        dnd5: {
          dragStart: function (node, data) { return true; },
          dragEnter: function (node, data) { return true; },
          dragDrop: function (node, data) { /* data.otherNode.copyTo(node, data.hitMode); */ }
        }
      });

      // getFolderData(nwPATH.join(app.project_path)).then(root_data => {
      //   fancytree().getRootNode().addChildren(root_data)
      // })
    });

    app.getElement("#file-explorer").classList.remove('hidden')
    app.getElement("#work-container").classList.add('with-file-explorer')
  }

  static hide() {
    app.getElement("#file-explorer").classList.add('hidden')
    app.getElement("#work-container").classList.remove('with-file-explorer')
  }

  static toggle() {
    app.getElement("#file-explorer").classList.toggle("hidden");
    app.getElement("#work-container").classList.toggle('with-file-explorer')
  }
}

document.addEventListener("fileChange", e => {
  nwFS.lstat(e.detail.file, (err, stats) => {
    if (!err) {
      const path_key = "/" + nwPATH.relative(app.project_path, e.detail.file);
      if (ignores.some(i => path_key.match(i))) return;

      FileExplorer.fileChanged(e.detail.file)
    }
  });
});

document.addEventListener("openProject", e => {
  FileExplorer.show();
});

document.addEventListener("closeProject", e => {
  FileExplorer.hide();
});
