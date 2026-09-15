class ExternalGotoArgs {
	public var projectPath : Null<String>;
	public var levelIid : Null<String>;
	public var entityIid : Null<String>;

	public function new() {}

	/** `rawArgv` is a full argv array (ie. process.argv layout: [execPath, ...args]) **/
	public static function fromRawArgv(rawArgv:Array<String>) : ExternalGotoArgs {
		var raw = rawArgv.copy();
		raw.shift(); // drop exe path, same convention as dn.js.ElectronTools.getArgs()
		var args = new dn.Args( raw.join(" ") );

		var out = new ExternalGotoArgs();
		// Filter out a lone "." solo value: Electron's own app-directory argument when launched unpackaged
		// as "electron.exe . <realArgs>" isn't stripped by the raw.shift() above (that only drops the exe
		// path), and a project path is never literally "." on its own — see App.getArgPath()'s identical fix.
		var soloValues = args.getAllSoloValues().filter( v -> v!="." );
		out.projectPath = soloValues.length>0 ? soloValues.join(" ") : null;
		out.levelIid = args.getArgParam("--goto-level");
		out.entityIid = args.getArgParam("--goto-entity");
		return out;
	}
}
