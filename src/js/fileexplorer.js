const $ = require("jquery");
require("jquery.fancytree");
require("jquery.fancytree/dist/modules/jquery.fancytree.persist");
require("jquery.fancytree/dist/modules/jquery.fancytree.dnd5");
require("jquery.fancytree/dist/modules/jquery.fancytree.edit");

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
  if (!nwFS.existsSync(folder_path)) return rej('no such dir', folder_path);
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
    if (!app.project_path) return;
    const true_path = trueCasePathSync(path);

    // file changes
    // iterate parent children
    // if old child file doesn't exist
    // if new child file path exists, rename the child title
    // else, remove the child
    const path_key = getKey(true_path);
    const parent_path = nwPATH.dirname(true_path);
    const parent_key = getKey(parent_path);

    const parent_node = fancytree().getNodeByKey(parent_key);

    if (parent_node && parent_node.children) {
      // iterate parent children
      nwFS.readdir(parent_path, (err, files) => {
        let found = false;

        parent_node.children.forEach(child_node => {
          const child_path = getPath(child_node.key);
          if (err || files.indexOf(child_path) === -1) {

            // if old child file doesn't exist
            nwFS.pathExists(path, (err2, exists) => {
              if (!err2 && exists && (getKey(path) === child_node.key || path_key === child_node.key)) {
                // if new child file path exists, rename the child title
                child_node.key = path_key;
                child_node.setTitle(nwPATH.basename(true_path))
                found = true;

              } else if (err2 || !exists) {
                // else, remove the child
                child_node.remove()
              }
            })
          }
        })

        if (!found) {
          // add new child?
          nwFS.pathExists(true_path, (err, exists) => {
            if (err || !exists) return;

            const child_node = fancytree().getNodeByKey(path_key)
            if (!child_node) {
              getFileData(true_path).then(child_data => {
                parent_node.addChildren([child_data])
              })
            }
          })
        }

      })
    }
  }

  static openFile(node) {
    const full_path = getPath(node.key);
    const asset_type = app.findAssetType(full_path);
    if (asset_type === "script") {
      Code.openScript(full_path);
    }
    else if (asset_type === "image") {
      ImageEditor.openImage(full_path);
    }
    else if (asset_type === "map") {
      SceneEditor.openScene(full_path)
    }
    else {
      remote.shell.openItem(full_path)
    }
  }

  static viewInExplorer(node) {
    const full_path = getPath(node.key);
    remote.shell.showItemInFolder(full_path);
  }

  static destroy() {
    const afterTran = () => {
      fancytree().destroy();
      app.getElement("#file-explorer").removeEventListener('transitionend', afterTran)
    }
    const el_fileexplorer = app.getElement("#file-explorer")

    if (el_fileexplorer.classList.contains('hidden'))
      afterTran();
    else
      el_fileexplorer.addEventListener('transitionend', afterTran)
    FileExplorer.hide();
  }

  static show() {
    const showElement = () => {
      app.getElement("#file-explorer").classList.remove('hidden')
      app.getElement("#work-container").classList.add('with-file-explorer')
    }
    // const walker = nwWALK.walk(app.project_path);
    // walker.on("file");
    if (fancytree()) {
      showElement();
      return;
    }

    $(function () {
      $("#file-explorer").fancytree({
        extensions: ["persist", "dnd5", "edit"],
        treeId: "/",
        selectMode: 1,
        clickFolderMode: 3,
        activeVisible: true,
        debugLevel: 0,
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
            FileExplorer.openFile(data.node);
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
          dragStart: function (src_node, data) {
            // add fake root
            fancytree().getRootNode().addNode({
              title: nwPATH.basename(app.project_path),
              key: "fake_root*",
              folder: true
            })
            return true;
          },
          dragEnter: function (target_node, data) {
            if (target_node.folder) return ["over", "before", "after"];
            return ["before", "after"];
          },
          dragDrop: function (target_node, data) {
            const src_node = data.otherNode;
            if (target_node.folder) {
              // dropping onto root?
              if (target_node.key === "fake_root*") target_node = fancytree().getRootNode();
              // move to folder
              const new_key = app.cleanPath(nwPATH.join(target_node.key, nwPATH.basename(src_node.key)));

              app.moveSafely(getPath(src_node.key), nwPATH.join(getPath(target_node.key), nwPATH.basename(src_node.key)), (err) => {
                if (!err) {
                  target_node.setExpanded(true); // expand new location
                  if (new_key !== src_node.key)
                    src_node.remove(); // remove old node
                }
              })
            }
            fancytree().getNodeByKey("fake_root*").remove();
          }
        },
        edit: {
          beforeClose: (e, data) => {
            const old_path = getPath(data.node.key);
            const new_path = nwPATH.join(nwPATH.dirname(old_path), data.input.val());
            app.renameSafely(old_path, new_path, (good) => {
              if (!good || old_path === new_path) {
                data.save = false;
              } else {
                data.node.remove();
              }
            })
          }
        }
      });

      // getFolderData(nwPATH.join(app.project_path)).then(root_data => {
      //   fancytree().getRootNode().addChildren(root_data)
      // })
    });

    showElement();
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
  FileExplorer.destroy();
});

document.addEventListener("ideReady", () => {
  app.getElement("#file-explorer").addEventListener('contextmenu', e => {
    const node = $.ui.fancytree.getNode(e.target)
    if (node) {
      app.contextMenu(e.x, e.y, [
        {
          label: `new folder in /${nwPATH.basename(node.folder ? node.key : nwPATH.dirname(node.key))}`,
          click: () => {
            var i = 1;
            var new_folder_name = 'folder' + i;
            var new_folder_path = getPath(node.folder ? node.key : nwPATH.dirname(node.key));
            // prevent using name of already existing dir
            while (nwFS.pathExistsSync(nwPATH.join(new_folder_path, new_folder_name))) {
              i++;
              new_folder_name = 'folder' + i;
            }
            new_folder_path = nwPATH.join(new_folder_path, new_folder_name);
            nwFS.ensureDir(new_folder_path);
          }
        },
        {
          label: 'open',
          click: () => { FileExplorer.openFile(node) }
        },
        {
          label: 'view in file explorer',
          click: () => { FileExplorer.viewInExplorer(node) }
        },
        {
          label: 'rename',
          click: () => {
            if (true || !FibWindow.isOpen(nwPATH.basename(node.key)))
              node.editStart();
            else {
              let toast = blanke.toast(`Can't rename file from File Explorer while the file is open!`);
              toast.icon = "close";
              toast.style = "bad";
            }
          }
        },
        {
          label: 'delete',
          click: () => {
            // modal
            app.deleteModal(getPath(node.key), {
              success: () => {
                node.remove();
              }
            })
          }
        }
      ])
    }
    e.preventDefault();
    return false;
  })
})
