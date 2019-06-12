var re_resolution = /resolution[\s=]*(?:(\d+)|{([\d\s]+),([\s\d]+)})/;

var removable = ["Audio","Bezier","Dialog","Effect","Map","Mask","Net","Physics","Repeater","Save","Scene","Steam","UI","View"];
var remove_path = {
	"Steam":[
		'blanke/Steam.lua',
		'blanke/extra/steamworks',
		'blanke/extra/ffi',
		'blanke/extra/steamworks/**/*',
		'blanke/extra/ffi/**/*'
	],
	"View":[
		'blanke/View.lua',
		'blanke/Camera.lua'
	]
}; // overrides default path building

class Exporter extends Editor {
	constructor (...args) {
		super(...args);
		let this_ref = this;

		if (DragBox.focus('Exporter')) return;

		// setup default settings
		if (!app.project_settings.export) app.project_settings.export = {};
		ifndef_obj(app.project_settings.export, {
			name: nwPATH.basename(app.project_path),
			remove_unused: true,
			web_autoplay: false,
			web_memory: 24,
			web_stack: 2
		});

		this.setupDragbox();
		this.setTitle('Exporter');
		this.removeHistory();
		this.hideMenuButton();

		this.container.width = 400;
		this.container.height = 370;

		// diplay list of target platforms
		this.platforms = ['windows','mac','linux','love','web'];

		this.el_platforms = app.createElement("div","platforms");
		let el_title1 = app.createElement("p","title1");
		el_title1.innerHTML = "One-click export";
		this.el_platforms.appendChild(el_title1);
		
		this.platforms.forEach(function(platform){
			let el_platform_container = app.createElement("button",["ui-button-rect","platform",platform]);

			if (platform == 'web') {
				el_platform_container.classList.add('danger');
				el_platform_container.title = "experimental feature!";
			}

			let el_platform_icon = app.createElement("img","icon");
			el_platform_icon.src = "icons/"+platform+".png";

			el_platform_container.value = platform;
			el_platform_container.addEventListener('click', function(e){
				this_ref.export(e.target.value);
			});

			el_platform_container.appendChild(el_platform_icon);
			this_ref.el_platforms.appendChild(el_platform_container);
		});

		this.appendChild(this.el_platforms);

		// extra options
		this.el_export_form = new BlankeForm([
			['general'],
			['name', 'text', {'default':app.project_settings.export.name}],
			//['remove_unused','checkbox',{'default':app.project_settings.export.remove_unused,label:"remove unused classes"}],
			['web'],
			['web_autoplay','checkbox',{'default':app.project_settings.export.web_autoplay,label:"autoplay"}],
		]);
		this.el_export_form.container.classList.add("dark");
		['name','remove_unused','web_autoplay','web_memory','web_stack'].forEach((s)=>{
			this_ref.el_export_form.onChange(s,(val)=>app.project_settings.export[s] = val);
		});

		this.appendChild(this.el_export_form.container);
	}

	createLove (dir, target_os, cb) {
		let love_path = nwPATH.join(dir, app.project_settings.export.name+".love");
		let engine_path = app.settings.engine_path;

		function startZipping(eng_ignore) {
			blanke.toast('Zipping files')
			app.saveSettings();

			let output = nwFS.createWriteStream(love_path);
			let archive = nwZIP('zip',{
				// zlib: { level: 9 }
			});

			// find the resolution
			let str_main = nwFS.readFileSync(nwPATH.join(app.project_path,'main.lua'),'utf-8');
			let match, resolution = [800,600];
			if (match = re_resolution.exec(str_main)) {
				if (match[1]) {
					let res = match[1] - 1;
					let aspect_ratio = [4,3];
					let res_list = [512,640,800,1024,1280,1366,1920];
					resolution = [
						res_list[res],
						res_list[res] / aspect_ratio[0] * aspect_ratio[1]
					];
				} else if (match[2]) {
					resolution = [match[2], match[3]];
				}
			}

			output.on('close', function(){
				// done
				if (cb) cb(love_path, resolution);
			});
			archive.pipe(output);
			archive.append(`
function love.conf(t) 
	t.window.title = "${app.project_settings.export.name}"         -- The window title (string)
	t.window.width = ${resolution[0]}                -- The window width (number)
	t.window.height = ${resolution[1]}              -- The window height (number)
end
			`, { name: 'conf.lua' });
			archive.glob("**/*",{
				cwd: nwPATH.join(engine_path,"lua"),
				ignore: (eng_ignore || [])
			})
			archive.glob("**/*",{
				cwd: app.project_path,
				ignore: ["dist","dist/**/*"]
			});
			archive.finalize();
		}

		app.project_settings.os = target_os;

		// remove uneccesary files
		if (app.project_settings.export.remove_unused) {
			blanke.toast('Removing unused classes');

			app.getAssets('script',function(files){
				let all_data = '';
				// iterate all scripts in project
				for (let fname of files) {
					let data = nwFS.readFileSync(fname,'utf-8');
					all_data += data;
					for (let r in removable) {
						// check if it's used anywhere in this file
						if (data.includes(removable[r])) {
							removable.splice(r,1);
						}
					}
				}
				// get a list of classes that shouldn't be in zip
				let new_removable = [];
				app.project_settings.ignore_modules = [];
				for (let key of removable) {
					if (remove_path[key])
						new_removable = new_removable.concat(remove_path[key]);
					else 
						new_removable.push(nwPATH.join('blanke',key+'.lua'));
				}
				new_removable.forEach((mod)=>{
					if (mod.includes('.lua')) app.project_settings.ignore_modules.push(nwPATH.basename(mod).split('.')[0]);
				});

				// iterate plugins too
				let plugins = nwFS.readdirSync(nwPATH.join(app.settings.engine_path,'lua','blanke','plugins'));
				let str_main = nwFS.readFileSync(nwPATH.join(app.project_path,"main.lua"));
				for (let p of plugins) {
					let name = nwPATH.parse(p).name;
					let re_plugin = new RegExp(`\\s*\\(\\s*['"]${name}['"]\\s*\\)|BlankE\\.init\\s*\\(\\s*['"\\w\\s]+\\s*,\\s*{['"\\w\\s=,]+plugins[\\s={"'\\w,]*${name}[=}"'\\w,]*`, 'g');

					if (!re_plugin.test(all_data)) 
						new_removable.push(nwPATH.join('blanke','plugins', p));
					
				}
				new_removable.push(nwPATH.join('blanke','docs'), nwPATH.join('blanke','docs','**','*'));

				startZipping(new_removable.map(app.cleanPath));
			});
		} else {
			startZipping();
		}
	}

	static openDistFolder(os) {
		nwGUI.Shell.openItem(nwPATH.join(app.project_path,"dist",os));
	}

	doneToast (os) {
		blanke.toast("Export done! <a href='#' onclick='Exporter.openDistFolder(\""+os+"\");'>View files</a>", 8000);
	}

	export (target_os) {
		let this_ref = this;
		let os_dir = nwPATH.join(app.project_path,"dist",target_os);
		let engine_path = app.settings.engine_path;
		let project_name = app.project_settings.export.name;

		blanke.toast("Starting export for "+target_os, 1000);
	
		nwFS.emptyDir(os_dir, function(err){
			// create a LOVE file
			this_ref.createLove(os_dir, target_os, function(love_path, resolution){
				if (target_os == "love") {
					this_ref.doneToast("love");
				}

				// export to WINDOWS
				if (target_os == "windows") {
					let exec_cmd = '';
					let exe_path = nwPATH.join(os_dir, project_name+".exe");

					// TODO: test on mac/linux
					// copy /b love.exe+game.love game.exe
					let f_loveexe = nwFS.createReadStream(nwPATH.join(engine_path,"love.exe"), {flags:'r', encoding:'binary'});
					let f_gamelove = nwFS.createReadStream(love_path, {flags:'r', encoding:'binary'});
					let f_gameexe = nwFS.createWriteStream(exe_path, {flags:'w', encoding:'binary'});
					// set up callbacks
					f_loveexe.on('end', ()=>{ f_gamelove.pipe(f_gameexe, {end:false}); })
					f_gamelove.on('end', ()=>{ f_gameexe.end(''); })
					// start merging
					f_loveexe.pipe(f_gameexe, {end:false});
					// finished all merging
					f_gameexe.on('finish', () => {
						nwFS.removeSync(love_path);
						// copy dlls and stuff
						nwFS.copySync(engine_path,os_dir,{filter:function(path){
							path = path.replace(process.cwd(),"");
							let exclude = [".app",".exe",/[\\\/]lua([\\\/]|\b)/];

							for (let e of exclude) {
								if (path.match(e)) {
									return false;
								}
							}
							return true;
						}});
		
						this_ref.doneToast("windows");
					});
				}

				// exporting to MAC
				if (target_os == "mac") {
					let app_path = nwPATH.join(os_dir,project_name+".app");
					nwFS.copySync(nwPATH.join(engine_path,"love.app"), app_path);
					nwFS.moveSync(love_path, nwPATH.join(app_path,"Contents","Resources",project_name+".love"));
					// make replacements in Info.plist
					nwFS.readFile(nwPATH.join(app_path,"Contents","Info.plist"), {encoding:'utf-8'}, function(err, data){
						if (err) { console.error(err); return; }

						data = data.replaceAll("org.love2d.love", "com.XHH."+project_name);
						data = data.replaceAll(/L\u00D6VE/g, project_name);
						data = data.replaceAll(/<key>UTExportedTypeDeclarations<\/key>\s*<array>[\s\S]+<\/array>/g, "");

						// change icon
						nwFS.copySync(app.project_settings.icns, nwPATH.join(app_path,"Contents","Resources","GameIcon.icns"));
						nwFS.copySync(app.project_settings.icns, nwPATH.join(app_path,"Contents","Resources","OS X AppIcon.icns"));
						// nwFS.copySync(app.project_settings.icns, nwPATH.join(app_path,"Contents","Resources","Document.icns"));

						nwFS.writeFile(nwPATH.join(app_path,"Contents","Info.plist"), data, function(err){
							if (err) { console.error(err); return; }
							this_ref.doneToast("mac")
						});
					})
				}

				// exporting to LINUX
				if (target_os == "linux") {
					// just keep it as a .love
					this_ref.doneToast("linux");
				}

				// exporting to WEB
				if (target_os == "web") {
					let html = `
<!DOCTYPE html>
<html lang="en-us">
<head>
	<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>${project_name}</title>
</head>
<body>
	<div id="my_game"></div>
	<script src="blanke.js"></script>
	<script type="text/javascript">
		(function(){loadGame('${project_name}.data','my_game',${!app.project_settings.export.web_autoplay},${resolution[0]},${resolution[1]});})();
	</script>
</body>
</html>`;
					let extrajs = `if(!game_loaded)var game_loaded={};if(!loadGame)var loadGame=function(data_file,div_id,play_on_focus,width,height){if(game_loaded['${project_name}'])return;let use_canvas_size=!(width||height);width=width||800;height=height||600;let el_parent,el_overlay,el_message,canvas,ctx;el_parent=document.getElementById(div_id);el_parent.setAttribute("style","width:"+width+"px;height:"+height+"px;background:#485358;position:relative");el_overlay=document.createElement("div");el_overlay.setAttribute("style","z-index:2;position:absolute;top:0;left:0;right:0;bottom:0;cursor:pointer;box-shadow: inset 0 0 5em 1em #000;");let overlay_inner=function(t){return'<div style="text-align: center;position: absolute;top: 50%;left: 50%;transform: translate(-50%,-50%);font-size: 28px;font-family: Trebuchet MS;color: white;text-shadow: 0px 0px 1px black, 0px 0px 1px black, 0px 0px 1px black, 0px 0px 3px black;padding: 3px;user-select:none;">'+t+'</div>'};el_overlay.innerHTML=overlay_inner("Loading...");el_message=document.createElement("div");el_message.setAttribute("style","z-index:3;position:absolute;top:0;left:0;outline:none;color:white;font-size:12px;text-shadow: 0px 0px 1px black, 0px 0px 1px black, 0px 0px 1px black, 0px 0px 3px black;padding:3px;");canvas=document.createElement('canvas');canvas.setAttribute("style","z-index:1;position:absolute;left:0;right:0");canvas.width=width||800;canvas.height=height||600;canvas.oncontextmenu=function(e){e.preventDefault()};ctx=canvas.getContext('2d');el_parent.appendChild(canvas);el_parent.appendChild(el_message);el_parent.appendChild(el_overlay);let TXT={LOAD:'Loading Game',EXECUTE:'Done loading',DLERROR:'Error while loading game data.\\nCheck your internet connection.',NOWEBGL:'Your browser or graphics card does not seem to support <a href="http://khronos.org/webgl/wiki/Getting_a_WebGL_Implementation">WebGL</a>.<br>Find out how to get it <a href="http://get.webgl.org/">here</a>.',};let Msg=function(m){ctx.clearRect(0,0,canvas.width,canvas.height);ctx.fillStyle='#888';for(var i=0,a=m.split('\\n'),n=a.length;i!=n;i++)ctx.fillText(a[i],20,20);};let Fail=function(m){el_parent.removeChild(el_overlay);el_message.innerHTML=TXT.NOWEBGL+(m?m:'')};let DoExecute=function(){Msg(TXT.EXECUTE);Module.canvas=canvas.cloneNode(!1);Module.canvas.oncontextmenu=function(e){e.preventDefault()};Module.setWindowTitle=function(title){};Module.postRun=function(){if(!Module.noExitRuntime){Fail();return};canvas.parentNode.replaceChild(Module.canvas,canvas);Txt=Msg=ctx=canvas=null;setTimeout(function(){if(use_canvas_size){el_parent.style.width=Module.canvas.widthNative+"px";el_parent.style.height=Module.canvas.heightNative+"px"};if(play_on_focus){Browser.mainLoop.pause();el_overlay.innerHTML=overlay_inner("Click to play");el_overlay.onclick=function(){el_parent.removeChild(el_overlay);Module.canvas.focus();Browser.mainLoop.resume()}}else{el_parent.removeChild(el_overlay);Module.canvas.focus()}},1)};Browser.requestAnimationFrame=function(f){window.requestAnimationFrame(f)};setTimeout(function(){Module.run(['/p'])},50)};let DoLoad=function(){Msg(TXT.LOAD);window.onerror=function(e,u,l){Fail(e+'<br>('+u+':'+l+')')};Module={ALLOW_MEMORY_GROWTH:1,TOTAL_MEMORY:1024*1024*${app.project_settings.web_memory},TOTAL_STACK:1024*1024*${app.project_settings.web_stack},currentScriptUrl:'-',preInit:DoExecute};var s=document.createElement('script'),d=document.documentElement;s.src=data_file;s.async=!0;game_loaded[data_file]=!0;s.onerror=function(e){el_parent.removeChild(el_overlay);d.removeChild(s);Msg(TXT.DLERROR);canvas.disabled=!1;game_loaded[data_file]=!1};d.appendChild(s)};DoLoad()}`;
					nwFS.readFile(love_path,'base64',(err, game_data)=>{
						if (err) console.error(err);	
						let gamejs = `FS.createDataFile('/p',0,FS.DEC('${game_data}'),!0,!0,!0)`;
						
						nwFS.readFile(nwPATH.join(cwd(),'src','includes','love.js'),'utf-8',(err, love_data)=>{
							if (err) console.error(err);
							let lovejs = love_data;

							nwFS.writeFileSync(nwPATH.join(os_dir,`blanke.js`),new Uint8Array(Buffer.from(extrajs)));
							nwFS.writeFileSync(nwPATH.join(os_dir,`${project_name}.data`),new Uint8Array(Buffer.from(lovejs + gamejs)));
							nwFS.removeSync(love_path);
								
							nwFS.writeFile(nwPATH.join(os_dir,'index.html'),html,'utf-8',(err)=>{
								if (err) console.error(err);
								this_ref.doneToast("web");
							});
						});
					});
				}
			});

		});
	}
}

document.addEventListener("openProject", function(e){
	app.removeSearchGroup("Exporter");
	app.addSearchKey({key: 'Export game', group:"Exporter", onSelect: function() {
		new Exporter(app);
	}});
});
