exports.info = {
    name: "Net.js",
    author: "XHH",
    description: "Simple networking plugin for BlankE",
    id: "xhh-net",
    enabled: true
}

exports.autocomplete = {
    class_list: 'Net',
    hints: {
        "blanke-net":[
            { fn: 'connect', vars: { address:'', port:'' } },
            { fn: 'disconnect' }
        ]
    }
}

exports.onPluginLoad = () => {
    document.addEventListener('script_modified', (e) => {
    let { path, content } = e.detail;
        if (!app.isServerRunning() && content.includes("Net.")) {								
            app.runServer();
        }
    });
}

exports.onPluginUnload = () => {
    
}