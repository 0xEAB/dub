/**
	Stuff with dependencies.

	Copyright: © 2012 Matthias Dondorff
	License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
	Authors: Matthias Dondorff
*/
module dub.package_;

import dub.dependency;
import dub.utils;

import std.array;
import std.conv;
import vibe.core.file;
import vibe.data.json;
import vibe.inet.url;


/// Representing an installed package
// Json file example:
// {
// 		"name": "MetalCollection",
// 		"author": "VariousArtists",
// 		"version": "1.0.0",
//		"url": "https://github.org/...",
//		"keywords": "a,b,c",
//		"category": "music.best",
// 		"dependencies": {
// 			"black-sabbath": ">=1.0.0",
// 			"CowboysFromHell": "<1.0.0",
// 			"BeneathTheRemains": ">=1.0.3"
// 		}
//		"licenses": {
//			...
//		}
// }
class Package {
	private {
		Json m_meta;
		Dependency[string] m_dependencies;
	}
	
	this(Path root) {
		m_meta = jsonFromFile(root ~ "package.json");
		m_dependencies = .dependencies(m_meta);
	}
	this(Json json) {
		m_meta = json;
		m_dependencies = .dependencies(m_meta);
	}
	
	@property string name() const { return cast(string)m_meta["name"]; }
	@property string vers() const { return cast(string)m_meta["version"]; }
	@property const(Url) url() const { return Url.parse(cast(string)m_meta["url"]); }
	@property const(Dependency[string]) dependencies() const { return m_dependencies; }

	string[] getDflags(string platform, string architecture)
	const {
		auto ret = appender!(string[])();
		foreach( j; m_meta["dflags"].opt!(Json[]) ) ret.put(j.get!string);
		foreach( j; m_meta["dflags-"~platform].opt!(Json[]) ) ret.put(j.get!string);
		foreach( j; m_meta["dflags-"~architecture].opt!(Json[]) ) ret.put(j.get!string);
		foreach( j; m_meta["dflags-"~platform~"-"~architecture].opt!(Json[]) ) ret.put(j.get!string);
		return ret.data;
	}

	string[] getLibs(string platform, string architecture)
	const {
		auto ret = appender!(string[])();
		foreach( j; m_meta["libs"].opt!(Json[]) ) ret.put(j.get!string);
		foreach( j; m_meta["libs-"~platform].opt!(Json[]) ) ret.put(j.get!string);
		foreach( j; m_meta["libs-"~architecture].opt!(Json[]) ) ret.put(j.get!string);
		foreach( j; m_meta["libs-"~platform~"-"~architecture].opt!(Json[]) ) ret.put(j.get!string);
		return ret.data;
	}
	
	string info() const {
		string s;
		s ~= cast(string)m_meta["name"] ~ ", version '" ~ cast(string)m_meta["version"] ~ "'";
		s ~= "\n  Dependencies:";
		foreach(string p, ref const Dependency v; m_dependencies)
			s ~= "\n    " ~ p ~ ", version '" ~ to!string(v) ~ "'";
		return s;
	}
	
	/// direct access to the json of this package
	@property ref Json json() { return m_meta; }
	
	/// Writes the json file back to the filesystem
	void writeJson(Path path) {
		auto dstFile = openFile((path~"package.json").toString(), FileMode.CreateTrunc);
		scope(exit) dstFile.close();
		Appender!string js;
		toPrettyJson(js, m_meta);
		dstFile.write( js.data );
	}
}
