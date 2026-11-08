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
            let remoteBuild = '';
            try {
              const vr = await fetch('version.json?t=' + Date.now(), { cache: 'no-store' });
              if (vr.ok) {
                const vj = await vr.json();
                remoteBuild = String(vj.build_number || '');
              }
            } catch (_) {}
            await Promise.allSettled([
              fetch(window.location.pathname, { cache: 'reload' }),
              fetch('flutter_bootstrap.js' + (remoteBuild ? '?v=' + remoteBuild : ''), { cache: 'reload' }),
              fetch('main.dart.js', { cache: 'reload' }),
              ...(remoteBuild ? [fetch('main.dart.js?v=' + remoteBuild, { cache: 'reload' })] : []),
            ]);
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
