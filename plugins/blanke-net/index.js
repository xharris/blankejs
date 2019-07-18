exports.autocomplete = {
    class_list: 'Net',
    hints: {
        "blanke-net":[
            { fn: 'join', vars: { address:'', port:'' } },
            { fn: 'disconnect' }
        ]
    }
}

exports.onPluginLoad = () => {
    document.addEventListener('script_modified', scriptModified);
}

exports.onPluginUnload = () => {
    
}

let scriptModified = (e) => {
    let { path, content } = e.detail;
    if (!app.isServerRunning() && content.includes("Net.")) {								
        app.runServer();
    }
}
