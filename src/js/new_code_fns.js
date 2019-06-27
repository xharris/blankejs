/* AUTOCOMPLETE

let color_vars = {
	r:'red component (0-1 or 0-255) / hex (#ffffff) / preset (\'blue\')',
	g:'green component',
	b:'blue component',
	a:'optional alpha'
}
let color_prop = '{r,g,b} (0-1 or 0-255) / hex (\'#ffffff\') / preset (\'blue\')';

// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Lexical_grammar#Keywords
// used Array.from(document.querySelectorAll("#Reserved_keywords_as_of_ECMAScript_2015 + .threecolumns code")).map((v)=>"'"+v.innerHTML+"'").join(',')
module.exports.keywords = [
	'break','case','catch','class','const','continue','debugger','default','delete',
	'do','else','export','extends','finally','for','function','if','import','in',
	'instanceof','new','return','super','switch','this','throw','try','typeof',
	'var','void','while','with','yield'
]

module.exports.class_list = ['Game','Util','Map']

module.exports.class_extends = {
    'entity': /\bclass\s+(\w+)\s+extends\s+Entity/g
}

module.exports.instance = {
	'entity': [
		/\b(\w+)\s*=\s*new\s+<class_name>\s*\(/g,
		/\b(\w+)\s*=\s*(?:\w+)\s*\.\s*spawnEntity/g
	],
	'map': /\b(\w+)\s*=\s*Map\.load\([\'\"].+[\'\"]\)\s+?/g
}

module.exports.user_words = {
	'var':[
		// single var
		/([a-zA-Z_]\w+?)\s*=\s(?!function|\(\)\s*=>)/g,
		// comma separated var list
		/(?:let|var)\s+(?:[a-zA-Z_]+[\w\s=]+?,\s*)+([a-zA-Z_]\w+)(?!\s*=)/g
	],
	'fn':[
		// var = function
		/([a-zA-Z_]\w+?)\s*=\s(?:function|\(\)\s*=>)/g,
		// function var()
		/function\s+([a-zA-Z_]\w+)\s*\(/g
	]
}

*/

var ext_class_list = {};// class_extends (Player)
var instance_list = {}; // instance (let player = new Player())
var var_list = {};      // user_words (let player;)
var class_list = []     // class_list (Map, Scene, Effect)

var re_class_extends, re_instance, re_user_words;

// called when autocomplete.js is modified
var reloadCompletions = () => {
    // get regex from autocomplete.js
    autocomplete = app.require(app.settings.autocomplete_path);
    re_class_extends = autocomplete.class_extends;
    re_instance = autocomplete.instance;
    re_user_words = autocomplete.user_words;
}

var getCompletionList = (_type) => {
    let retrieve = (obj) => {
        let ret_obj = {};
        // do you like loops??
        for (let file in obj) {
            for (let cat in obj[file]) {
                ret_obj[cat] = [];
                for (let name of obj[file][cat]) {
                    if (!ret_obj[cat].includes(name)) {
                        obj[file][cat].push(name);
                    }
                }
            }
        }
    }
    let arrays = {
        'ext-class':ext_class_list,
        'instance': instance_list,
        'var':      var_list,
        'class':    class_list      // array
    }
    if (arrays[_type]) {
        return retrieve(arrays[_type]);
    }
}

// replaces refreshObjectList ** called when a file is modified
var getKeywords = (file, content) => {
    blanke.cooldownFn('getKeywords.'+file, 500, ()=>{
        ext_class_list[file] = {};
        instance_list[file] = {};
        var_list[file] = {};

        // read file
        let data = content || nwFS.readFileSync(file,'utf-8')
        if (!data) return;

        // should a server be running?
        if (!app.isServerRunning() && content.includes("Net.")) {								
            app.runServer();
        }

        let match = (regex, store_list) => {
            for (let cat in regex) {
                // clear old list of results
                store_list[file][cat] = [];
                // one regex or muliple?
                if (!Array.isArray(regex)) regex = [regex];
                let match;
                while (match = regex.exec(data))
                    if (!store_list[file][cat].includes(m[1]))
                        store_list[file][cat].push(m[1]);
            }
        }
        // start scanning
        ext_class_list[file] = {};
        match(re_class_extends, ext_class_list);        // user-made classes
        instance_list[file] = {};
        // add user class regexes
        let new_re_instance = {};
        let re_instance_copy = [].concat(re_instance);
        for (let cat in re_instance_copy) {
            new_re_instance[cat] = [];
            for (let re of re_instance_copy[cat]) {
                if (re.source.includes('<class_name>')) {
                    // YES - make the replacement
                    if (ext_class_list[file][cat]) {
                        // iterate user-made classes
                        for (let class_name of ext_class_list[file][cat]) {
                            new_re_instance[cat].push(new RegExp(re.source.replace('<class_name>', class_name)))
                        }
                    }
                } else {
                    // NO - add current regex
                    new_re_instance[cat].push(re);
                }
            }
        }
        match(new_re_instance, instance_list);
        var_list[file] = {};
        match(re_user_words, var_list);
    });
}

CodeMirror.defineMode("blanke", (config, parserConfig) => {
    var blankeOverlay = {
        token: (stream, state) => {
            let baseCur = stream.lineOracle.state.baseCur;
            if (baseCur == null) baseCur = "";
            else baseCur += " ";
            var ch;

            getKeywords(this_ref.file, this_ref.codemirror.getValue());

            // comment
            if (stream.match(/\s*\/\//) || baseCur.includes("comment")) {
                while ((ch = stream.next()) != null && !stream.eol());
                return "comment";
            }

            // instance
            let instances = getCompletionList('instance');
            for (let cat in instances) { // Player, Map
                for (let name of instances[cat]) { // player1, map1
                    if (stream.match(new RegExp("^"+name))) 
                        return baseCur+`blanke-instance blanke-${cat}-instance`;
                }
            }

            // extended classes
            let ext_classes = getCompletionList('ext-class');
            for (let cat in ext_classes) { // Entity
                for (let name of ext_classes[cat]) { // Player
                    if (stream.match(new RegExp("^"+name))) 
                        return baseCur+`blanke-class blanke-${cat}`;
                }
            }

            // regular classes
            let classes = getCompletionList('ext-class');
            for (let name of classes[cat]) { // Map, Scene
                if (stream.match(new RegExp("^"+name))) 
                    return baseCur+`blanke-class blanke-${cat}`;
            }

            // this keyword
            if (stream.match(/^this/g)) {
                return baseCur+"blanke-this";
            }

            while (stream.next() && false) {}
            return null;
        }
    };
    return CodeMirror.overlayMode(CodeMirror.getMode(config, parserConfig.backdrop || "javascript"), blankeOverlay);
});

new_editor.on('change', (cm, e) => {
    let editor = cm;
    let cursor = editor.getCursor();

    let word_pos = editor.findWordAt(cursor);
    let word = editor.getRange(word_pos.anchor, word_pos.head);
    let before_word_pos = {line: word_pos.anchor.line, ch: word_pos.anchor.ch-1};
    let before_word = editor.getRange(before_word_pos, {line:before_word_pos.line, ch:before_word_pos.ch+1});
    let word_slice = word.slice(-1);

    checkGutterEvents(editor);
    blanke.cooldownFn('checkLineWidgets',250,()=>{otherActivity(cm,e)})

    this_ref.parseFunctions();
    this_ref.addAsterisk();
    this_ref.refreshFnHelperTimer();


});

