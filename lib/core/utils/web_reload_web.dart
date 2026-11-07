import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('window')
external JSObject get _window;

class WebReloadImpl {
  static Future<bool> forceUpdateAndReload() async {
    try {
      const script = '''
        (async function() {
          try {
            if ('serviceWorker' in navigator) {
              const regs = await navigator.serviceWorker.getRegistrations();
              for (const r of regs) { await r.unregister(); }
            }
            if ('caches' in window) {
              const keys = await caches.keys();
              for (const k of keys) { await caches.delete(k); }
            }
          } catch (_) {}
          const url = new URL(window.location.href);
          url.searchParams.set('hopal_v', Date.now().toString());
          window.location.replace(url.toString());
        })();
      ''';
      _window.callMethod('eval'.toJS, script.toJS);
      return true;
    } catch (_) {
      return false;
    }
  }
}
