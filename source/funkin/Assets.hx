package funkin;

import openfl.utils.Future;
import openfl.utils.AssetType;
import funkin.util.macro.ConsoleMacro;

@:nullSafety
class Assets implements ConsoleClass
{
  public static var cache:openfl.utils.IAssetCache = openfl.utils.Assets.cache;

  public static function getPath(path:String):String
  {
    assertPath(path);
    return openfl.utils.Assets.getPath(path);
  }

  public static function getBytes(path:String):haxe.io.Bytes
  {
    assertPath(path);
    return openfl.utils.Assets.getBytes(path);
  }

  public static function loadBytes(path:String):Future<openfl.utils.ByteArray>
  {
    assertPath(path);
    return openfl.utils.Assets.loadBytes(path);
  }

  public static function getText(path:String):String
  {
    assertPath(path);
    return openfl.utils.Assets.getText(path);
  }

  public static function loadText(path:String):Future<String>
  {
    assertPath(path);
    return openfl.utils.Assets.loadText(path);
  }

  public static function getSound(path:String):openfl.media.Sound
  {
    assertPath(path);
    return openfl.utils.Assets.getSound(path);
  }

  public static function loadSound(path:String):Future<openfl.media.Sound>
  {
    assertPath(path);
    return openfl.utils.Assets.loadSound(path);
  }

  public static function getMusic(path:String):openfl.media.Sound
  {
    assertPath(path);
    return openfl.utils.Assets.getMusic(path);
  }

  public static function loadMusic(path:String):Future<openfl.media.Sound>
  {
    assertPath(path);
    return openfl.utils.Assets.loadMusic(path);
  }

  public static function getBitmapData(path:String, useCache:Bool = true):openfl.display.BitmapData
  {
    assertPath(path);
    return openfl.utils.Assets.getBitmapData(path, useCache);
  }

  public static function loadBitmapData(path:String):Future<openfl.display.BitmapData>
  {
    assertPath(path);
    return openfl.utils.Assets.loadBitmapData(path);
  }

  public static function getFont(path:String):openfl.text.Font
  {
    assertPath(path);
    return openfl.utils.Assets.getFont(path);
  }

  public static function loadFont(path:String):Future<openfl.text.Font>
  {
    assertPath(path);
    return openfl.utils.Assets.loadFont(path);
  }

  public static function exists(path:String, ?type:AssetType):Bool
  {
    if (path == null || path.length == 0) return false;
    return openfl.utils.Assets.exists(path, type);
  }

  public static function isLocal(path:String, ?type:AssetType, useCache:Bool = true):Bool
  {
    assertPath(path);
    return openfl.utils.Assets.isLocal(path, type, useCache);
  }

  public static function getAssetType(path:String):Null<AssetType>
  {
    assertPath(path);
    return openfl.utils.Assets.getAssetType(path);
  }

  public static function list(?type:AssetType):Array<String>
  {
    var result = openfl.utils.Assets.list(type);
    return result == null ? [] : result;
  }

  public static function hasLibrary(name:String):Bool
  {
    if (name == null || name.length == 0) return false;
    return openfl.utils.Assets.hasLibrary(name);
  }

  public static function getLibrary(name:String):Null<lime.utils.AssetLibrary>
  {
    if (name == null || name.length == 0) return null;
    return openfl.utils.Assets.getLibrary(name);
  }

  public static function loadLibrary(name:String):Future<openfl.utils.AssetLibrary>
  {
    if (name == null || name.length == 0) throw 'Cannot load a library with an empty name.';
    return openfl.utils.Assets.loadLibrary(name);
  }

  public static function unloadLibrary(name:String):Void
  {
    if (name == null || name.length == 0) return;
    openfl.utils.Assets.unloadLibrary(name);
  }

  static inline function assertPath(path:String):Void
  {
    if (path == null || path.length == 0) throw 'Asset path cannot be null or empty.';
  }
}
