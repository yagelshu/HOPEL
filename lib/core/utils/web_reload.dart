import 'web_reload_stub.dart'
    if (dart.library.js_interop) 'web_reload_web.dart';

class WebReload {
  static Future<bool> forceUpdateAndReload() => WebReloadImpl.forceUpdateAndReload();
}
