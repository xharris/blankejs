/* AUTOCOMPLETE

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
var refreshCompletions = () => {
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
        'class':    ext_class_list,
        'instance': instance_list,
        'var':      var_list
    }
    if (arrays[_type]) {
        return retrieve(arrays[_type]);
    }
}

// ** called when a file is modified
var getKeywords = (file, content) => {
    ext_class_list[file] = {};
    instance_list[file] = {};
    var_list[file] = {};

    blanke.cooldownFn('getUserClasses.'+file, 500, ()=>{
        // read file
        let data = content || nwFS.readFileSync(file,'utf-8')
        if (!data) return;

        let append = (key, list) => { if (!list.includes) list.push(key); }
        let match = (regex, store_list) => {
            store_list[file] = {};
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
        match(re_class_extends, ext_class_list);        // user-made classes
        match(re_instance, instance_list);
        match(re_user_words, var_list);

    });
}

CodeMirro.defineMode("blanke", (config, parserConfig) => {
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
            for (let cat in instances) {
                for (let name of instances[cat]) {
                    if (stream.match(new RegExp("^"+name))) 
                        return baseCur+`blanke-instance blanke-${cat}-instance`;
                }
            }

            // extended classes
            return baseCur+"blanke-class blanke-"+match[1].toLowerCase();

            // class
            

            if (re_class_list) {
                let match = stream.match(new RegExp(re_class_list));
                if (match) {
                    console.log('class',stream.string,match[1])
                    
                }
            }

            // user made classes (PlayState, Player)
            for (let category in object_list) {
                if (re_class[category]) {
                    
                    let re_obj_category = '^\\s(';
                    for (let obj_name in object_list[category]) {
                        re_obj_category += obj_name+'|';
                    }

                    if (Object.keys(object_list[category]).length > 0) {
                        if (stream.match(new RegExp(re_obj_category.slice(0,-1)+')'))) {
                            if (category=='entity') console.log(re_obj_category.slice(0,-1)+')')
                            ;//return baseCur+"blanke-class blanke-"+category;
                        }
                    }

                }
            }

            // self keyword
            if (stream.match(/^self/g)) {
                return baseCur+"blanke-self";
            }

            while (stream.next() && false) {}
            return null;

            /* keeping this code since it's a good example
            if (stream.match("{{")) {
                while ((ch = stream.next()) != null)
                    if (ch == "}" && stream.next() == "}") {
                        stream.eat("}");
                        return "blanke-test";
                    }
            }
            */	
        }
        };
        return CodeMirror.overlayMode(CodeMirror.getMode(config, parserConfig.backdrop || "javascript"), blankeOverlay);
});

