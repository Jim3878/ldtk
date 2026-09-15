import electron.main.App;
import electron.main.IpcMain;
import js.Node.__dirname;
import js.Node.process;

class ElectronMain {
	static var mainWindow : electron.main.BrowserWindow;

	static var settings : Settings;

	// External "goto level/entity" forwarding (see second-instance handling below)
	static var rendererReady = false;
	static var pendingExternalGoto : Null<ExternalGotoArgs> = null;

	static function main() {
		// Single instance lock: if another LDtk instance is already running, forward our
		// args to it (via the 'second-instance' event below) and quit this one immediately.
		if( !App.requestSingleInstanceLock() ) {
			App.quit();
			return;
		}

		settings = new Settings();

		// Force best available GPU usage
		if( settings.v.useBestGPU && !App.commandLine.hasSwitch("force_low_power_gpu") )
			App.commandLine.appendSwitch("force_high_performance_gpu");

		App.whenReady().then( (_)->showSplashWindow() );

		// Another instance was started with args (eg. "LDtk.exe project.ldtk --goto-level=xxx --goto-entity=yyy"):
		// forward those args to our own renderer, and bring our window to front.
		App.on("second-instance", (event, argv:Array<String>, workingDirectory:String) -> {
			var req = ExternalGotoArgs.fromRawArgv(argv);
			if( mainWindow!=null ) {
				if( mainWindow.isMinimized() )
					mainWindow.restore();
				mainWindow.show();
				mainWindow.focus();
			}
			if( rendererReady )
				sendExternalGoto(req);
			else
				pendingExternalGoto = req;
		});

		// Mac
		App.on('window-all-closed', function() {
			mainWindow = null;
			App.quit();
		});
		App.on('activate', ()->{
			if( electron.main.BrowserWindow.getAllWindows().length == 0 )
				showSplashWindow();
		});

		initIpcBindings();
	}


	static function initIpcBindings() {
		// *** invoke/handle *****************************************************

		IpcMain.handle("appReady", function(ev) {
			// Window close button
			mainWindow.on('close', function(ev) {
				if( !dn.js.ElectronUpdater.isIntalling ) {
					ev.preventDefault();
					mainWindow.webContents.send("onWinClose");
				}
			});
			// Window move
			mainWindow.on('move', function(ev) {
				mainWindow.webContents.send("onWinMove");
			});

			// Renderer is now ready to receive IPC events: flush any pending external goto request
			// that arrived (via 'second-instance') before this point.
			rendererReady = true;
			if( pendingExternalGoto!=null ) {
				sendExternalGoto(pendingExternalGoto);
				pendingExternalGoto = null;
			}
		});


		// *** sendSync/on *****************************************************
	}

	static function sendExternalGoto(req:ExternalGotoArgs) {
		mainWindow.webContents.send("externalGoto", req.projectPath, req.levelIid, req.entityIid);
	}

	static function fileNotFound(file:String) {
		electron.main.Dialog.showErrorBox("File not found", '"$file" was not found in app assets!');
		App.quit();
	}


	static var splash : electron.main.BrowserWindow = null;
	static function showSplashWindow() {
		#if debug

			createMainWindow();

		#else

			splash = new electron.main.BrowserWindow({
				width: 300,
				height: 300,
				alwaysOnTop: true,
				transparent: true,
				frame: false,
			});

			var ver = new dn.Version( MacroTools.getAppVersion() );

			splash
				.loadFile('assets/splash.html', { query:{
					mainVersion : ver.major+"."+ver.minor,
					patchVersion : ver.patch>0 ? "."+ver.patch : "",
				}})
				.then(
					_->createMainWindow(),
					_->fileNotFound("splash.html")
				);

		#end

	}

	static function createMainWindow() {
		// Init window
		mainWindow = new electron.main.BrowserWindow({
			webPreferences: { nodeIntegration:true, contextIsolation:false },
			fullscreenable: true,
			show: false,
			title: "LDtk",
			icon: __dirname+"/appIcon.png",
			backgroundColor: '#1e2229'
		});
		mainWindow.once("ready-to-show", ev->{
			mainWindow.webContents.setZoomFactor( settings.getAppZoomFactor() );
			if( settings.v.startFullScreen )
				dn.js.ElectronTools.setFullScreen(true);
			mainWindow.webContents.send("settingsApplied");
		});
		dn.js.ElectronTools.initMain(mainWindow);

		// Window menu
		#if debug
			enableDebugMenu();
		#else
			// electron.main.Menu.setApplicationMenu( electron.main.Menu.buildFromTemplate( [] ) ); // macos
			mainWindow.removeMenu(); // windows
		#end

		// Load app page
		var p = mainWindow.loadFile('assets/app.html');
		#if debug
			// Show immediately
			mainWindow.maximize();
			p.then( (_)->{}, (_)->fileNotFound("app.html") );
		#else
			// Wait for loading before showing up
			p.then( (_)->{
				mainWindow.show();
				mainWindow.maximize();
				splash.destroy();
			}, (_)->{
				splash.destroy();
				fileNotFound("app.html");
			});
		#end

		// Destroy
		mainWindow.on('closed', function() {
			mainWindow = null;
		});

		// Misc bindings
		dn.js.ElectronDialogs.initMain(mainWindow);
		dn.js.ElectronUpdater.initMain(mainWindow);
	}



	// Create a custom debug menu
	#if debug
	static function enableDebugMenu() {
		var menu = electron.main.Menu.buildFromTemplate([{
			label: "Debug tools",
			submenu: cast [
				{
					label: "Reload",
					click: function() mainWindow.reload(),
					accelerator: "CmdOrCtrl+R",
				},
				{
					label: "Dev tools",
					click: function() mainWindow.webContents.toggleDevTools(),
					accelerator: "CmdOrCtrl+Shift+I",
				},
			]
		}]);

		mainWindow.setMenu(menu);
	}
	#end
}
