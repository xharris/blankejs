
// requires jQuery Color Picker (http://www.laktek.com/2008/10/27/really-simple-color-picker-in-jquery/)

function ifndef(val, def) {
    if (val == undefined) return def;
    return val
}

function ifndef_obj(obj, defaults) {
    if (obj === undefined) obj = {};
    for (let d in defaults) {
        if (obj[d] === undefined) obj[d] = defaults[d];
    } 
    return obj;
}

function guid() {
  function s4() {
    return Math.floor((1 + Math.random()) * 0x10000)
    .toString(16)
    .substring(1 );
}
return s4() + s4();
}

function htmlEncode(s) {
    var el = document.createElement("div");
    el.innerText = el.textContent = s;
    s = el.innerHTML;
    return s;
}

const isFloat = n => typeof(n) == "string" ? n.includes('.') : Number(n) === n && n % 1 !== 0;

// Extend the string type to allow converting to hex for quick access.
String.prototype.toHex = function() {
    function intToARGB(i) {
        var hex = ((i>>24)&0xFF).toString(16) +
                ((i>>16)&0xFF).toString(16) +
                ((i>>8)&0xFF).toString(16) +
                (i&0xFF).toString(16);
        // Sometimes the string returned will be too short so we 
        // add zeros to pad it out, which later get removed if
        // the length is greater than six.
        hex += '000000';
        return hex.substring(0, 6);
    }

    function hashCode(str) {
        var hash = 0;
        for (var i = 0; i < str.length; i++) {
            hash = str.charCodeAt(i) + ((hash << 5) - hash);
        }
        return hash;
    }
    return intToARGB(hashCode(this));
}

String.prototype.toRgb = function() {
    let hex = this;

    // Expand shorthand form (e.g. "03F") to full form (e.g. "0033FF")
    var shorthandRegex = /^#?([a-f\d])([a-f\d])([a-f\d])$/i;
    hex = hex.replace(shorthandRegex, function(m, r, g, b) {
        return r + r + g + g + b + b;
    });

    var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result ? {
        r: parseInt(result[1], 16),
        g: parseInt(result[2], 16),
        b: parseInt(result[3], 16)
    } : null;
}

String.prototype.replaceAll = function(find, replace) {
    return this.replace(new RegExp(find, 'g'), replace);
};

String.prototype.escapeSlashes = function() {
    return this.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|\"\']/g, "\\$&");
}

String.prototype.hashCode = function(){
	var hash = 0;
	if (this.length == 0) return hash;
	for (i = 0; i < this.length; i++) {
		char = this.charCodeAt(i);
		hash = ((hash<<5)-hash)+char;
		hash = hash & hash; // Convert to 32bit integer
	}
	return Math.abs(hash).toString();
}

String.prototype.addSlashes = function() 
{ 
   //no need to do (str+'') anymore because 'this' can only be a string
   return this.replace(/[\\"']/g, '\\$&').replace(/\u0000/g, '\\0');
} 

// min <= x < max
function randomRange(min, max) {
    return Math.random() * (max-min) + min;
}

function dispatchEvent(ev_name, ev_properties) {
    var new_event = new CustomEvent(ev_name, {'detail': ev_properties});
    document.dispatchEvent(new_event);
}

class BlankeListView {
    constructor (options) {
        var this_ref = this;

        this.options = ifndef_obj(options,{
            object_type:"item",
            controls:["add","move-up","move-down"],
            title:""
        });

        this.container = blanke.createElement("div","list-view-container");

        this.selected_text = '';
        this.el_selected;

        // add title
        if (this.options.title) {
            let el_title = blanke.createElement("p","list-title");
            el_title.innerHTML = this.options.title;
            this.container.appendChild(el_title);
        }

        // add item container
        this.el_items_container = blanke.createElement("div","items-container");

        // add list action buttons
        let controls = {
            "add":[
                "plus", "add a"+('aeiouy'.includes(this.options.object_type.charAt(0)) ? 'n' : '')+" "+this.options.object_type,
                function(e){ 
                    let new_item = this_ref._getNewItemName();
                    let ret = this_ref.onItemAdd(new_item);
                    if (ret !== false)
                        this_ref.addItem(ret || new_item);
            }],
            "move-up":[
                "chevron-up",`move ${this.options.object_type} up`,
                function(e){
                    if (this_ref.el_selected && this_ref.el_selected.previousElementSibling) {
                        let el_other = this_ref.el_selected.previousElementSibling;
                        el_other.parentNode.insertBefore(this_ref.el_selected, el_other);
                        this_ref.onItemSwap(this_ref.el_selected.el_text.innerHTML, el_other.el_text.innerHTML);
                    }
            }],
            "move-down":[
                "chevron-down",`move ${this.options.object_type} down`,
                function(e){
                    if (this_ref.el_selected && this_ref.el_selected.nextElementSibling) {
                        let el_other = this_ref.el_selected.nextElementSibling;
                        el_other.parentNode.insertBefore(this_ref.el_selected, el_other.nextSibling);
                        this_ref.onItemSwap(this_ref.el_selected.el_text.innerHTML, el_other.el_text.innerHTML);
                    }
            }]
        };
        let el_actions_container = blanke.createElement("div","actions-container");
        for (let ctrl of this.options.controls) {
            let el_action = blanke.createElement("button",["ui-button-sphere",ctrl]);
            let el_icon = blanke.createElement("i",["mdi","mdi-"+controls[ctrl][0]]);

            el_action.appendChild(el_icon);
            el_action.title = controls[ctrl][1];
            el_action.addEventListener('click', controls[ctrl][2]);

            el_actions_container.appendChild(el_action);
        }

        this.container.appendChild(el_actions_container);
        this.container.appendChild(this.el_items_container);
    }

    setItems (list) {
        this.clearItems();
        for (let item of list) {
            this.addItem(item);
        }
    }

    clearItems () {
        blanke.clearElement(this.el_items_container);
    }

    hasItem (text) {
        let children = this.el_items_container.children;
        for (let c = 0; c < children.length; c++) {
            if (children[c].title == text) return true;
        }
        return false;
    }

    _getNewItemName () {
        let item_list = this.getItems();
        let count = item_list.length;
        let text = this.options.object_type+count;
        while (item_list.includes(text)) {
            count++;
            text = this.options.object_type+count;
        }
        return text;
    }

    addItem (text) {
        if (this.hasItem(text)) return;
        if (!text) text = this._getNewItemName();

        let el_item_container = blanke.createElement("div","item");
        let el_item_text = blanke.createElement("span","item-text");
        let el_item_actions = blanke.createElement("div","item-actions");

        el_item_text.innerHTML = text;
        el_item_text.style.pointerEvents = "none";

        // add item actions
        if (this.options.actions) {
            for (let opt in this.options.actions) {
                let el_action = blanke.createElement("button","ui-button-sphere");
                let el_icon = blanke.createElement("i",["mdi","mdi-"+opt]);

                el_action.title = opt;
                el_action.addEventListener('click', e => {
                    e.stopPropagation();
                    this.onItemAction(opt, text);
                });

                el_action.appendChild(el_icon);
                el_item_actions.appendChild(el_action);
            }
        }

        // add item click event
        el_item_container.el_text = el_item_text;
        el_item_container.title = text;
        el_item_container.addEventListener('click', e => {
            this.selectItem(e.target.el_text.innerHTML);
            this.onItemSelect(e.target.el_text.innerHTML);
        });

        el_item_container.appendChild(el_item_text);
        el_item_container.appendChild(el_item_actions);

        this.el_items_container.appendChild(el_item_container);

        // was the list cleared and it was already a selection?
        if (this.selected_text == text)
            this.selectItem(text);

        return 
    }

    // highlight it, but dont trigger the event
    selectItem (text) {
        // clear element selection class
        let el_selected;
        let children = this.el_items_container.children;
        for (let c = 0; c < children.length; c++) {
            children[c].classList.remove('selected');

            if (children[c].el_text.innerHTML == text)
                el_selected = children[c];
        }

        if (el_selected) {
            el_selected.classList.add('selected');
            this.selected_text = el_selected.innerHTML;
            this.el_selected = el_selected;
        }
    }

    removeItem (text, reselect_another) {
        let children = this.el_items_container.children;
        let del_c = -1;
        for (let c = 0; c < children.length; c++) {
            if (children[c].el_text.innerHTML == text) {
                if (this.selected_text == text) {
                    this.selected_text = '';
                    this.el_selected = undefined;
                }
                blanke.destroyElement(children[c]);
                del_c = c;
            }
        }

        if (reselect_another) {
            if (del_c == 0) del_c++;
            if (del_c > children.length) del_c = children.length - 1;
            if (del_c >= 0) {
                this.selectItem(children[del_c-1].el_text.innerHTML);
                return children[del_c-1].el_text.innerHTML;
            } else {
                return false;
            }
        }
    }

    renameItem (text, new_text) {
        let children = this.el_items_container.children;
        for (let c = 0; c < children.length; c++) {
            if (children[c].el_text.innerHTML == text) {
                if (this.selected_text == text) this.selected_text = text;
                children[c].el_text.innerHTML = new_text;
                children[c].title = new_text;
            }
        }
    }

    setItemColor (text, color) {
        let children = this.el_items_container.children;
        for (let c = 0; c < children.length; c++) {
            if (children[c].el_text.innerHTML == text) {
                children[c].style.outlineColor = color;
                children[c].style.borderColor = color;
            }
        }
    }

    getItems () {
        let ret_list = [];
        let children = this.el_items_container.children;
        for (let c = 0; c < children.length; c++) {
            ret_list.push(children[c].el_text.innerHTML)
        }
        return ret_list;
    }

    onItemAdd (text) { }

    onItemAction (item_icon, item_text) { }

    onItemSelect (item_text) { }

    // for move-up and move-down
    onItemSwap (item1_text, item2_text) {}
}

class BlankeForm {
    /*  inputs = [ [input_name, input_type, {other_args}] ]
        
        input types (input_type {extra_args})
            - text {
                inputs = 1, number of input boxes
                separator = '', separator between multiple input boxes
                default = null
            }
            - number {
                ...same as text,
                step,
                min,
                max
            }
    */
    constructor (inputs, dark) {
        this.container = blanke.createElement("div", "form-container");
        this.arg_inputs = inputs;
        this.input_ref = {};
        this.input_values = {};
        this.input_types = {};
        this.input_args = {};
        this.first_header = null;

        for (var input of inputs) {
            this.addInput(input, true);
        }
        if (inputs.length > 0 && this.first_header) {
            this.toggleHeader(this.first_header);
        }

        if (dark)
            this.container.classList.add("dark");
    }

    toggleHeader (nextEl) {
        let hiding = false;
        while (nextEl) {
            if (nextEl.is_header) {
                hiding = nextEl.hide;
            } 
            // get whether this header is hidden or not
            if (nextEl.is_header) {
                if (hiding) {
                    nextEl.classList.add('hidden');
                    nextEl.innerHTML = nextEl.title + "...";
                } else { 
                    nextEl.classList.remove('hidden');
                    nextEl.innerHTML = nextEl.title;
                }
            }
            // hide this input?
            else {
                if (hiding) {
                    nextEl.classList.add('header-hidden');
                    nextEl.style.display = "none";
                } else {
                    nextEl.classList.remove('header-hidden');
                    nextEl.style.display = null;
                }
            }
            nextEl = nextEl.nextSibling;
        }
    }

    addInput (input, internal) {
        if (input.length < 1) return;

        let input_name = input[0];
        let input_type = input[1];
        let extra_args = input[2] || {};

        // header element
        if (input.length <= 2 && typeof(input_type) != 'string') {
            let el_header = app.createElement("div","form-header");
            el_header.hide = true;
            el_header.is_header = true;
            el_header.innerHTML = input_name;
            el_header.title = input_name;
            if (!this.first_header) 
                this.first_header = el_header;
            
            el_header.addEventListener('click', e => {
                e.target.hide = !e.target.hide;
                this.toggleHeader(e.target);
            });
            el_header.hide = (input_type === true);

            this.container.appendChild(el_header);
            return;
        }

        this.input_ref[input_name] = [];
        this.input_values[input_name] = [];
        this.input_types[input_name] = input_type;
        this.input_args[input_name] = extra_args;

        let container_type = "div";
        if (input_type == "checkbox")
            container_type = "label";

        let el_container    = blanke.createElement(container_type, "form-group");
        let el_label        = blanke.createElement("p", "form-label");
        let el_inputs_container=blanke.createElement("div","form-inputs");

        let prepend_inputs = false;
        // input label
        let show_label = extra_args.label;
        let label = input_name.replace(/\w+\.(.*)/,'$1');

        if (show_label === false || ['button','icon-button'].includes(input_type))
            show_label = false;

        el_container.setAttribute("data-type", input_type);
        el_label.innerHTML = (show_label || label.replaceAll('_',' '));
        if (show_label !== false) 
            el_container.appendChild(el_label);

        if (input_type == "button") {
            let el_button = blanke.createElement("button","form-button");
            el_button.innerHTML = ifndef(extra_args.label, label);
            this.prepareInput(el_button, input_name);
            el_inputs_container.appendChild(el_button);
        }

        if (input_type == 'icon-button') {
            let el_button = blanke.createIconButton(extra_args.icon || label, input_name);
            this.prepareInput(el_button, input_name);
            el_inputs_container.appendChild(el_button);
        }
        
        if (input_type == "text" || input_type == "number") {
            let input_count = 1;
            if (extra_args.inputs) input_count = extra_args.inputs;
            el_container.setAttribute("data-size", input_count);

            // add inputs
            for (var i = 0; i < input_count; i++) {
                let el_text = blanke.createElement("input","form-text");
                // set starting val
                if (Array.isArray(extra_args.default)) {
                    el_text.value = ifndef(extra_args.default[i], input_type == "text" ? "" : "0");
                } else
                    el_text.value = ifndef(extra_args.default, input_type == "text" ? "" : "0");
                // set input type
                el_text.type = input_type;

                // NUMBER only
                if (input_type == "number") {
                    for (let attr of ['step','min','max']) {
                        if (extra_args[attr] != null) el_text[attr] = extra_args[attr];
                    }
                }

                this.prepareInput(el_text, input_name, i);

                el_text.setAttribute('data-index',i);
                el_inputs_container.appendChild(el_text);

                // add separator if necessary
                if (i < input_count - 1) {
                    let el_sep = blanke.createElement("p","form-separator");
                    el_sep.innerHTML = extra_args.separator || 'x';
                    el_inputs_container.appendChild(el_sep);
                }
            }
        }

        if (input_type == "checkbox") {
            let el_checkbox = blanke.createElement("input","form-checkbox");
            el_checkbox.type = "checkbox";
            el_checkbox.checked = (extra_args.default ? true : false);
            this.prepareInput(el_checkbox, input_name);

            let el_checkmark = blanke.createElement("span","checkmark");

            el_inputs_container.appendChild(el_checkbox);
            el_inputs_container.appendChild(el_checkmark);
            prepend_inputs = true;
        }

        if (input_type == "color") {
            let el_input = blanke.createElement("input","form-color");
            el_input.type = "color";
            this.prepareInput(el_input, input_name);
            el_inputs_container.appendChild(el_input);
        }

        if (input_type == "select") {
            let el_input = blanke.createElement("select","form-select");
            
            if (extra_args.placeholder) {
                let placeholder = app.createElement("option");
                placeholder.selected = (!extra_args.default ? true : false);
                placeholder.disabled = true;
                placeholder.hidden = true;
                placeholder.innerHTML = extra_args.placeholder;
                el_input.appendChild(placeholder);
            }

            // add choices
            if (extra_args.choices)
                for (let c of extra_args.choices) {
                    var new_option = app.createElement("option");
                    new_option.value = c;
                    if (extra_args.default == c) new_option.selected = true;
                    new_option.innerHTML = c;
                    el_input.appendChild(new_option);
                }

            this.prepareInput(el_input, input_name);
            el_inputs_container.appendChild(el_input);
        }

        if (input_type == "directory" || input_type == "file") {
            let el_input = blanke.createElement("input","form-file-input");
            let el_file_btn = blanke.createElement("button","form-file-btn");
            el_file_btn.innerHTML = "choose";

            el_input.placeholder = extra_args.placeholder || '';
            el_input.value = extra_args.default || '';
            this.prepareInput(el_input, input_name);

            el_inputs_container.appendChild(el_input);
            el_inputs_container.appendChild(el_file_btn);

            // select folder dialog
            el_file_btn.addEventListener('click',(e)=>{
                blanke.chooseFile({
                    properties:[(input_type == 'directory' ? 'openDirectory' : 'openFile')]
                },
                function(file_path){
                    el_input.value = file_path;
                    el_input.dispatchEvent(new Event('input',{ bubbles: true }));
                });
            });
        }

        if (prepend_inputs)
            el_container.prepend(el_inputs_container);
        else
            el_container.appendChild(el_inputs_container);
        el_container.setAttribute('data-name',input_name);

        this.container.appendChild(el_container);
        if (!internal)
            ;// this.hideHeader(this.first_header); // TODO what is hideHeader?
    }

    hideInput (name) {
        for (var i = 0; i < this.container.children.length; i++) {
            let container = this.container.children[i];
            if (container.dataset.name == name) {
                container.classList.add('input-hidden');
            }
        }
    }

    showInput (name) {
        for (var i = 0; i < this.container.children.length; i++) {
            let container = this.container.children[i];
            if (container.dataset.name == name) {
                container.classList.remove('input-hidden');
            }
        }
    }

    removeInput (name) {
        for (var i = 0; i < this.container.children.length; i++) {
            if (this.container.children[i].dataset.name == name) {
                blanke.destroyElement(this.container.children[i]);
            }
        }
    }

    // "private" method
    prepareInput (element, name, index) {
        element.name_ref = name;
        this.input_ref[name].push(element);
        let input_type = this.input_types[name];
        let _default = input_type == "text" ? "" : "0";
        let args = this.input_args[name];
        // tooltip
        if (args.desc)
            element.title = args.desc;
        // default value
        if (args.default)
            this.input_values[name][index || 0] = (index != null ? args.default[index] : args.default);
        else
            this.input_values[name][index || 0] = (input_type == "text" ? "" : 0);
    }

    getInput (input_name) {
        if (this.input_ref[input_name].length == 1)
            return this.input_ref[input_name][0];
        return this.input_ref[input_name];
    }

    // if the enter key is pressed while an input is focused
    onEnter (input_name, func) {
        let this_ref = this;
        for (var input of this.input_ref[input_name]) {
            input.addEventListener('keyup', function(e){
                if (event.keyCode === 13)
                    func(e);
            });
        }
    }

    /*
    func(value[] or value)
        return array/value to override field values
    */
    onChange (input_name, func) {
        let this_ref = this;
        if (!this.input_ref[input_name]) return;
        for (var input of this.input_ref[input_name]) {
            let event_type = 'input';

            if (["color", "select", "checkbox"].includes(this.input_types[input_name])) event_type = "change";
            if (["button","icon-button"].includes(this.input_types[input_name])) event_type = "click";

            input.addEventListener(event_type, function(e){
                let input_type = this_ref.input_types[e.target.name_ref];
                let input_value = this_ref.input_values[e.target.name_ref];
                let input_ref = this_ref.input_ref[input_name];
                let input_args = this_ref.input_args[input_name];

                let val;
                if (input_type == "text" ||
                    input_type == "select" ||
                    input_type == "color" ||
                    input_type == "directory" ||
                    input_type == "file"
                   ) {
                    val = e.target.value;
                    if (val == '' && e.target.placeholder)
                        val = input_args.default || '';
                }
                
                if (input_type == "checkbox")
                    val = this.checked;

                if (input_type == "number") 
                    val = isFloat(e.target.value) ? parseFloat(e.target.value) : parseInt(e.target.value);

                input_value[parseInt(e.target.dataset['index']) || 0] = val;
                let ret_val = func(input_value.length == 1 ? input_value[0] : input_value.slice());
                // concat is so that the re

                // if values are returned, set the inputs to them
                if (ret_val) {
                    if (Array.isArray(ret_val)) {
                        for (var input2 in input_ref) {
                            input_ref[input2].value = ret_val[input2];
                        }
                    } else {
                        input_ref[0].value = ret_val;
                    }
                }
            });
        }
    }

    getValue (input_name, index) {
        index = index || 0;
        if (this.input_types[input_name] == "number") {
            let val = this.input_ref[input_name][index].value;
            return isFloat(val) ? parseFloat(val) : parseInt(val);
        }
        else if (this.input_types[input_name] == "checkbox")
            return this.input_ref[input_name][index].checked;
        else
            return this.input_ref[input_name][index].value;
    }

    setValue (input_name, value, index) {
        if (!this.input_ref[input_name] || value == null) return;
        index = index || 0;
        let input_type = this.input_types[input_name];
        if (input_type == "checkbox")
            this.input_ref[input_name][index].checked = value;
        else if (input_type == "select") {
            let opts = Array.from(this.input_ref[input_name][index].options);
            for (let i = 0; i < opts.length; i++) {
                let opt = opts[i];
                if (opt.value == value) {
                    this.input_ref[input_name][index].selectedIndex = i;
                    break;
                }
            }
        } else
            this.input_ref[input_name][index].value = value;
        this.input_values[input_name][index] = value;
    }

    useValues (inputs) {
        for (let name in inputs) {
            if (Array.isArray(inputs[name])) {
                for (let i in inputs[name]) {
                    this.setValue(name, inputs[name][i], i);
                }
            } else {
                this.setValue(name, inputs[name])
            }
        }
    }
}

class Toast {
    constructor (text, duration, die_cb) {
        if (!Toast.el_toasts) {
            Toast.el_toasts = blanke.createElement('div','blankejs-toasts');
            document.body.appendChild(Toast.el_toasts);
        }
        this.el_new_toast = blanke.createElement("div","toast-container");
        this.el_content = blanke.createElement("p","content");
        this.el_icon = blanke.createElement("object")
        this.el_icon.classList.add('blanke-icon');
        this.el_icon.type = 'image/svg+xml';
        this.el_br = blanke.createElement("br");

        this.el_icon.addEventListener('click',() => { this.die(0); })

        this.el_new_toast.appendChild(this.el_content);
        this.el_new_toast.appendChild(this.el_icon);

        Toast.el_toasts.appendChild(this.el_new_toast);
        Toast.el_toasts.appendChild(this.el_br);

        // animate toast appearance
        Array.from(Toast.el_toasts.children).forEach(function(el) {
            let animation = [
                { transform: 'translateY('+el.offsetHeight+'px)' },
                { transform: 'translateY(0px)' }
            ];
            el.animate(animation, {
                duration: 200,
                iterations: 1,
                easing: 'ease-out'
            });
        });

        // duration
        if (duration == null || duration > 0)
            this.die(duration, die_cb);

        this.style = 'none';
        this.text = text;
    }
    set text (v) {
        this.el_content.innerHTML = v;
    }
    // go away after t ms
    die (t, cb) {
        setTimeout(()=>{
            let animation = this.el_new_toast.animate([{ opacity:1 }, { opacity:0 }], { duration:200, iterations:1, easing:'ease-in'})
            animation.pause();
            animation.onfinish = () => {
                blanke.destroyElement(this.el_new_toast);
                blanke.destroyElement(this.el_br);
            }
            animation.play();
            if (cb) cb();
        }, t || 4000);
    }
    set icon (v) {
        this.el_icon.style.display = 'inline-block';
        this.el_icon.data = `icons/${v}.svg`;
    }
    set style (v) {
        let styles = {
            'none':'212121',
            'wait':'fff176',
            'good':'8BC34A',
            'bad':'f44336'
        }
        if (styles[v]) 
            this.el_icon.style.backgroundColor = '#'+styles[v];
    }
}
Toast.el_toasts = null;

var blanke = {
    elec_ref: null,
    _windows: {},

    getElement: function(sel) {
        return document.querySelector(sel);
    },

    getElements: function(sel) {
        return document.querySelectorAll(sel);
    },

    createElement: function(el_type, el_class) {
        var ret_el = document.createElement(el_type);
        if (Array.isArray(el_class)) ret_el.classList.add(...el_class);
        else if (el_class) ret_el.classList.add(el_class);
        return ret_el;
    },

    createIconButton: function(icon, title) { 
		let el_btn = app.createElement("button","icon-button");
		let el_icon = app.createElement("object","blanke-icon");
		el_icon.data = "icons/"+icon+".svg";
		el_icon.type = "image/svg+xml";
		el_icon.innerHTML = icon[0].toUpperCase();
		el_btn.appendChild(el_icon);
		el_btn.title = title;
		el_btn.change = (icon2, title2) => {
			el_icon.data = "icons/"+icon2+".svg";
			el_icon.innerHTML = icon2[0].toUpperCase();
			el_btn.title = title2;
		}
		return el_btn;
    },

    clearElement: function(element) {
        while (element.firstChild) {
            element.removeChild(element.firstChild);
        }
    },

    destroyElement: function(element) {    
        if (element.parentNode) 
            element.parentNode.removeChild(element);
    },

    removeChildClass: function(element, class_name) {   
		for (let c = element.children.length -1; c >= 0; c--) {
			if (element.children[c].classList.contains(class_name))
			    element.removeChild(element.children[c]);
		}
    },

    sortChildren: function(element, fn_compare) {
        let sorted_children = Array.from(element.children);
        sorted_children.sort(fn_compare);
        blanke.clearElement(element);
        for (let e = 0; e < sorted_children.length; e++) {
            element.appendChild(sorted_children[e]);
        }
    },
    cooldown_keys: {},
    cooldownFn: function(name, cooldown_ms, fn, overwrite_timer) {
        if (!blanke.cooldown_keys[name]) {
            blanke.cooldown_keys[name] = {
                timer: null,
                func: fn
            }
        }
        
        // reset the timer if necessary
        if (overwrite_timer || blanke.cooldown_keys[name].timer == null) {
            clearTimeout(blanke.cooldown_keys[name].timer);
            blanke.cooldown_keys[name].timer = setTimeout(function(){
                let fn_ref = blanke.cooldown_keys[name].func;
                delete blanke.cooldown_keys[name];
                fn_ref();
            },cooldown_ms);
        }

        blanke.cooldown_keys[name].func = fn;
    },

    askColor: (color, onChange) => {
        let el_color = document.getElementById('blanke-color-input')
        if (!el_color) {
            el_color = app.createElement('input');
            document.body.appendChild(el_color);
        }
        el_color.id = "blanke-color-input";
        el_color.type = "color";
        el_color.value = color;
        el_color.style.position = "absolute";
        el_color.style.left = "-10000000px";
        el_color.style.width = "1px";
        el_color.style.height = "1px";
        el_color.style.overflow = "hidden";
        el_color.focus();
        el_color.click();
        el_color.addEventListener('change', e => {
            onChange(e);
        });
    },

    el_toasts: undefined,
    toast: function(text, duration) {
        return new Toast(text, duration)
    },
    
    places: function(i, p) {
        return Math.floor(i * (Math.pow(10,p))) / (Math.pow(10,p));
    },

    chooseFile: function(options, cb) { //type, onChange, filename='', multiple=false) {
        if (!blanke.elec_ref) return;
        blanke.elec_ref.remote.dialog.showOpenDialog(options,(files)=>{
            if (!files)
                return;
            if (files.length == 1)
                cb(files[0]);
            else
                cb(files);
        })
    },

    // possible choices: yes, no (MORE TO COME LATER)
    modal_shown: false,
    showModal: function(html_body, choices) {
        if (blanke.modal_shown) return;
        blanke.modal_shown = true;
        html_actions = "";
        choice_keys = Object.keys(choices);

        // fill in action buttons
        for (var c = 0; c < choice_keys.length; c++) {
            var choice_key = choice_keys[c];

            btn_type = "sphere";
            html_inside = choice_key;
            if (choice_key.toLowerCase() == "yes") {
                html_inside = "<i class='mdi mdi-check'></i>"
            }
            else if (choice_key.toLowerCase() == "no") {
                html_inside = "<i class='mdi mdi-close'></i>"
            }
            else {
                html_inside = choice_key
                btn_type = "rect"
            }

            html_actions += "<button class='ui-button-"+btn_type+"' data-action='"+choice_key+"'>"+html_inside+"</button>";
        }

        // add dialog to page
        var uuid = guid();
        var e = document.createElement('div');
        e.innerHTML = 
            "<div class='ui-modal' data-uuid='"+uuid+"'>"+
                "<div class='modal-body'>"+html_body+"</div>"+
                "<div class='modal-actions'>"+html_actions+"</div>"+
            "</div>";
        while(e.firstChild) {
            document.body.appendChild(e.firstChild);
        }

        // bind button events with their choice functions
        choice_keys.forEach(function(c){
            var choice_fn = choices[c];

            blanke.getElement("body > .ui-modal[data-uuid='"+uuid+"'] > .modal-actions > button[data-action='" + c + "']").onclick = function(){
                choice_fn();
                blanke.modal_shown = false;
                blanke.getElement("body > .ui-modal[data-uuid='"+uuid+"']").remove();
            };
        });
    },

    extractDefaults: function(settings) {
        var ret_parameters = {};

        // fill in parameters with default values of audio_settings
        var categories = Object.keys(settings);
        for (var c = 0; c < categories.length; c++) {
            var setting;
            ret_parameters[categories[c]] = {};
            for (var s = 0; s < settings[categories[c]].length; s++) {
                setting = settings[categories[c]][s];
                if (typeof setting.default != "object")
                    ret_parameters[setting.name] = setting.default;
            }
        }

        return ret_parameters;
    },

    createWindow: function(options) {
        var x = options.x;
        var y = options.y;
        var width = options.width;
        var height = options.height;
        var extra_class = options.class;
        var title = options.title;
        var html = ifndef(options.html, '');
        var uuid = ifndef(options.uuid, guid());
        var onClose = options.onClose;
        var onResizeStop = options.onResizeStop;

        if ($(this._windows[uuid]).length > 0) {
            $(this._windows[uuid]).trigger('mousedown');
            return this._windows[uuid];
        }

        var el = "body > .blanke-window[data-guid='"+uuid+"']";
        this._windows[uuid] = el;

        $("body").append(
            "<div class='blanke-window "+extra_class+"' data-guid='"+uuid+"'>"+
                "<div class='title-bar'>"+
                    "<div class='title'>"+title+"</div>"+
                    "<button class='btn-close'>"+
                        "<i class='mdi mdi-close'></i>"+
                    "</button>"+
                "</div>"+
                "<div class='content'>"+html+"</div>"+
            "</div>"
        );
        $(el).fadeIn("fast");

        // set initial position
        $(".blanke-window").css("z-index", "0");
        $(el).css({
            "left": x + "px",
            "top": y + "px",
            "width": width + "px",
            "height": height + "px",
            "z-index": "1"
        });

        $(el).resizable({
            stop: function( event, ui ) {
                if (onResizeStop)
                    onResizeStop(event, ui);
            }
        });

        // bring window to top
        $(el).on("mousedown focus", function(e){
            $(".blanke-window").css("z-index", "0");
            $(this).css("z-index", "1");
        });

        // add title-bar drag listeners
        function _divMove(e) {
            var div = document.querySelector(el);
            div.style.left = (e.clientX - offX) + 'px';
            div.style.top = (e.clientY - offY) + 'px';
        }
        var offX, offY;
        $(el + " > .title-bar").on("mousedown", function(e){
            $(el + " > .content").css("pointer-events", "none");

            var div = $(el)[0];
            offX = e.clientX - parseInt(div.offsetLeft);
            offY = e.clientY - parseInt(div.offsetTop);

            window.addEventListener('mousemove', _divMove, true);
        });

        $(window).on("mouseup", function(e){
            $(el + " > .content").css("pointer-events", "all");
            window.removeEventListener('mousemove', _divMove, true);
        });

        // close event
        $(el + " > .title-bar > .btn-close").on("click", function(e){
            var can_close = true;
            if (onClose) {
                can_close = ifndef(onClose(), true); // if onClose returns false, prevent closing
            }
            if (can_close) {
                $(el).remove();
            }       
        });

        return el;
    }
}

