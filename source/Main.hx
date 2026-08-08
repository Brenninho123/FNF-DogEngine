package;

import lime.system.System;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import funkin.ui.FullScreenScaleMode;
import funkin.Preferences;
import funkin.PlayerSettings;
import funkin.util.logging.CrashHandler;
import funkin.ui.debug.FunkinDebugDisplay;
import funkin.ui.debug.FunkinDebugDisplay.DebugDisplayMode;
import funkin.save.Save;
#if hxvlc
import hxvlc.util.Handle;
#end
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.Lib;
import openfl.media.Video;
import openfl.net.NetStream;
import funkin.util.WindowUtil;

using funkin.util.AnsiUtil;

@:nullSafety
class Main extends Sprite
{
  static final DEFAULT_GAME_WIDTH:Int = 1280;
  static final DEFAULT_GAME_HEIGHT:Int = 720;
  static final AUTO_ZOOM:Float = -1;

  var gameWidth:Int = DEFAULT_GAME_WIDTH;
  var gameHeight:Int = DEFAULT_GAME_HEIGHT;
  var initialState:Class<FlxState> = funkin.InitState;
  var zoom:Float = AUTO_ZOOM;
  var skipSplash:Bool = true;

  public static var debugDisplay:Null<FunkinDebugDisplay>;

  public static function main():Void
  {
    #if android
    Sys.setCwd(haxe.io.Path.addTrailingSlash(extension.androidtools.content.Context.getExternalFilesDir()));
    #elseif ios
    Sys.setCwd(haxe.io.Path.addTrailingSlash(lime.system.System.documentsDirectory));
    #end

    CrashHandler.initialize();
    CrashHandler.queryStatus();

    Lib.current.addChild(new Main());
  }

  public function new()
  {
    super();

    haxe.Log.trace = funkin.util.logging.AnsiTrace.trace;
    funkin.util.logging.AnsiTrace.traceBF();

    openfl.utils._internal.Log.level = openfl.utils._internal.Log.LogLevel.INFO;

    loadMods();

    if (stage != null)
    {
      init();
    }
    else
    {
      addEventListener(Event.ADDED_TO_STAGE, init);
    }
  }

  function loadMods():Void
  {
    try
    {
      funkin.modding.PolymodHandler.loadAllMods();
    }
    catch (e)
    {
      Logger.error('Failed to load mods: ${e.message}');
    }
  }

  function init(?event:Event):Void
  {
    if (hasEventListener(Event.ADDED_TO_STAGE))
    {
      removeEventListener(Event.ADDED_TO_STAGE, init);
    }

    #if (sys && !mobile)
    configureDesktopExitHandler();
    #end

    if (!validateRenderContext())
    {
      return;
    }

    setupGame();
  }

  #if (sys && !mobile)
  function configureDesktopExitHandler():Void
  {
    Lib.current.stage.window.onClose.add(function()
    {
      Logger.warn('Game is exiting, cleaning up resources...');

      #if hxvlc
      Handle.dispose();
      #end

      Sys.exit(0);
    });
  }
  #end

  function validateRenderContext():Bool
  {
    var context = stage.window.context.type;

    if (context == WEBGL || context == OPENGL || context == OPENGLES)
    {
      return true;
    }

    var tech:String = #if web "WebGL" #elseif desktop "OpenGL" #else "OpenGL ES" #end;
    var requiredVersion:String = #if web '$tech 1.0 or newer' #elseif desktop '$tech 3.0 or newer' #else '$tech 2.0 or newer' #end;
    var desc:String = 'Failed to initialize the $tech rendering context!\n\n';

    #if web
    desc += 'Make sure your graphics card supports $requiredVersion, your graphics drivers are up to date, and hardware acceleration is enabled on your browser.';
    #elseif desktop
    desc += 'Make sure your graphics card supports $requiredVersion, and your graphics drivers are up to date.';
    #else
    desc += 'Make sure your device supports $requiredVersion.';
    #end

    WindowUtil.showError('Failed to initialize $tech', desc);
    System.exit(1);

    return false;
  }

  function setupGame():Void
  {
    #if FEATURE_HAXEUI
    initHaxeUI();
    #end

    debugDisplay = new FunkinDebugDisplay(10, 10, 0xFFFFFF);

    FlxG.signals.postUpdate.add(handleDebugDisplayKeys);

    #if mobile
    FlxG.signals.preUpdate.add(repositionCounters.bind(true));
    #end

    Save.load();

    #if hxvlc
    initializeHxvlc();
    #end

    WindowUtil.setVSyncMode(funkin.Preferences.vsyncMode);

    forceFunkinCameraFrontEnd();

    var game:FlxGame = createGame();

    addChild(game);

    #if FEATURE_DEBUG_FUNCTIONS
    #if !FLX_NO_DEBUG game.debugger.interaction.addTool(new funkin.util.TrackerToolButtonUtil()); #end
    funkin.util.macro.ConsoleMacro.init();
    #end

    #if !html5
    FlxG.scaleMode = new FullScreenScaleMode();
    #end

    #if mobile
    repositionCounters(false);
    #end

    logDebugServerStatus();
  }

  #if hxvlc
  function initializeHxvlc():Void
  {
    Handle.initAsync(function(success:Bool):Void
    {
      if (success)
      {
        Logger.info('LibVLC instance initialized!');
      }
      else
      {
        Logger.warn('LibVLC instance failed to initialize!');
      }
    });
  }
  #end

  function forceFunkinCameraFrontEnd():Void
  {
    untyped FlxG.cameras = new funkin.graphics.FunkinCameraFrontEnd();
  }

  function createGame():FlxGame
  {
    var framerate:Int = Preferences.unlockedFramerate ? 0 : Preferences.framerate;

    var game:FlxGame = new FlxGame(gameWidth, gameHeight, initialState, framerate, framerate, skipSplash,
      (FlxG.stage.window.fullscreen || Preferences.autoFullscreen));

    @:privateAccess
    game._customSoundTray = funkin.ui.options.FunkinSoundTray;

    return game;
  }

  function logDebugServerStatus():Void
  {
    #if hxcpp_debug_server
    Logger.info('hxcpp_debug_server is enabled! You can now connect to the game with a debugger.');
    #else
    Logger.info('hxcpp_debug_server is disabled! This build does not support debugging.');
    #end
  }

  #if FEATURE_HAXEUI
  function initHaxeUI():Void
  {
    haxe.ui.locale.LocaleManager.instance.autoSetLocale = false;
    haxe.ui.Toolkit.init();
    haxe.ui.Toolkit.theme = 'dark';
    haxe.ui.Toolkit.autoScale = false;
    haxe.ui.focus.FocusManager.instance.autoFocus = false;
    funkin.input.Cursor.registerHaxeUICursors();
    haxe.ui.tooltips.ToolTipManager.defaultDelay = 200;
  }
  #end

  function handleDebugDisplayKeys():Void
  {
    if (PlayerSettings.player1.controls == null || !PlayerSettings.player1.controls.check(DEBUG_DISPLAY)) return;

    var nextMode:DebugDisplayMode;

    switch (Preferences.debugDisplay)
    {
      case DebugDisplayMode.Off:
        nextMode = DebugDisplayMode.Simple;
      case DebugDisplayMode.Simple:
        nextMode = DebugDisplayMode.Advanced;
      case DebugDisplayMode.Advanced:
        nextMode = DebugDisplayMode.Off;
    }

    Preferences.debugDisplay = nextMode;
  }

  #if mobile
  function repositionCounters(lerp:Bool):Void
  {
    var scale:Float = Math.max(Math.min(FlxG.stage.stageWidth / FlxG.width, FlxG.stage.stageHeight / FlxG.height), 1);

    if (debugDisplay == null) return;

    debugDisplay.scaleX = debugDisplay.scaleY = scale;

    if (FlxG.game == null) return;

    final thypos:Float = Math.max(FullScreenScaleMode.notchSize.x, 10);

    if (lerp)
    {
      debugDisplay.x = flixel.math.FlxMath.lerp(debugDisplay.x, FlxG.game.x + thypos, FlxG.elapsed * 3);
    }
    else
    {
      debugDisplay.x = FlxG.game.x + thypos;
    }

    debugDisplay.y = FlxG.game.y + (3 * scale);
  }
  #end
}

class Logger
{
  public static function info(message:String):Void
  {
    Sys.println(' INFO '.bold().bg_blue() + ' ' + message);
  }

  public static function warn(message:String):Void
  {
    Sys.println(' WARN '.bold().bg_yellow() + ' ' + message);
  }

  public static function error(message:String):Void
  {
    Sys.println(' ERROR '.bold().bg_red() + ' ' + message);
  }
}
