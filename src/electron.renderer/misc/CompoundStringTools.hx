package misc;

import data.DataTypes;

// Pure string helpers for the "String + hidden Bool/Enum/String/Float sub-fields" compound
// encoding used by F_String fields that have FieldDef.compoundSubFields set.
// Format: "primary?key=value&key2=value2" (first "?" splits primary from params).
class CompoundStringTools {

	public static function splitPrimary(raw:Null<String>) : { primary:String, query:String } {
		if( raw==null )
			return { primary:"", query:"" };

		var idx = raw.indexOf("?");
		return idx<0
			? { primary:raw, query:"" }
			: { primary:raw.substr(0,idx), query:raw.substr(idx+1) };
	}

	public static function parseParams(query:String) : Map<String,String> {
		var out = new Map();
		if( query==null || query.length==0 )
			return out;

		for( pair in query.split("&") ) {
			if( pair.length==0 )
				continue;
			var eq = pair.indexOf("=");
			if( eq<0 )
				out.set( StringTools.urlDecode(pair), "" );
			else
				out.set( StringTools.urlDecode(pair.substr(0,eq)), StringTools.urlDecode(pair.substr(eq+1)) );
		}
		return out;
	}

	public static function buildRaw(primary:String, subFields:Array<CompoundSubFieldDef>, values:Map<String,String>) : String {
		if( primary==null )
			primary = "";

		var parts = [];
		for( sf in subFields ) {
			var v = values.get(sf.key);
			switch sf.kind {
				case CF_Bool:
					if( v=="true" )
						parts.push( sf.key+"=true" );

				case CF_Enum, CF_String:
					if( v!=null && v.length>0 )
						parts.push( sf.key+"="+StringTools.urlEncode(v) );

				case CF_Float:
					if( v!=null && v.length>0 )
						parts.push( sf.key+"="+v );
			}
		}

		return parts.length==0 ? primary : primary+"?"+parts.join("&");
	}

}
