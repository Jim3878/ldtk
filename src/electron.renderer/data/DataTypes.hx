package data;

/*
	WARNING: all the follow types are serialized when saving a Project:
		- do not remove Enum values,
		- Enum values CANNOT be renamed (they are stored as strings)
		- do not rename Typedef fields or change their type
*/

typedef IntGridValueDefEditor = {
	var value : Int;
	var identifier : Null<String>;
	var color : dn.Col;
	var tile : Null<ldtk.Json.TilesetRect>;
	var groupUid : Int;
}

enum ValueWrapper {
	V_Int(v:Int);
	V_Float(v:Float);
	V_Bool(v:Bool);
	V_String(v:String);
}

// Extra Bool/Enum "sub-fields" that can be attached to a F_String FieldDef.
// They are only UI/editing sugar: the actual value stays a single V_String,
// baked as "primary?key=value&key2=value2".
enum CompoundSubFieldKind {
	CF_Bool;
	CF_Enum;
	CF_String;
	CF_Float;
}

typedef CompoundSubFieldDef = {
	var key : String; // query string param name, eg. "bubble"
	var kind : CompoundSubFieldKind;
	var enumDefUid : Null<Int>; // only used when kind==CF_Enum
	var floatDefault : Null<Float>; // only used when kind==CF_Float
}

typedef TilesetSelection = {
	var ids : Array<Int>;
	var mode : TileEditMode;
}

enum TileEditMode {
	Stamp;
	Random;
}

typedef EnumDefValue = {
	var id : String;
	var tileRect : Null<ldtk.Json.TilesetRect>;
	var color: Int;
}

typedef GridTileInfos = {
	var tileId : Int;
	var flips : Int;
}

typedef CachedImage = {
	var relPath: String;
	var fileName: String;
	var base64: String;
	var bytes: haxe.io.Bytes;
	var pixels: hxd.Pixels;
	var tex: h3d.mat.Texture;
}