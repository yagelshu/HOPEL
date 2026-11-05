import 'dart:js_interop';

@JS('eval')
external JSAny? _jsEval(JSString code);

@JS('__hopalBioV2.isAvailable')
external JSPromise<JSBoolean> _jsIsAvailable();

@JS('__hopalBioV2.register')
external JSPromise<JSString> _jsRegister(JSString userId, JSString userName);

@JS('__hopalBioV2.authenticate')
external JSPromise<JSBoolean> _jsAuthenticate(JSString credentialId);

bool _bridgeInitialized = false;

void _ensureBridgeInstalled() {
  if (_bridgeInitialized) return;
  const script = r'''
(function() {
  if (window.__hopalBioV2) return;
  function toBase64Url(buffer) {
    var bytes = new Uint8Array(buffer);
    var binary = '';
    for (var i = 0; i < bytes.byteLength; i++) {
      binary += String.fromCharCode(bytes[i]);
    }
    return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
  }
  function fromBase64Url(str) {
    var base64 = str.replace(/-/g, '+').replace(/_/g, '/');
    while (base64.length % 4) base64 += '=';
    var binary = atob(base64);
    var bytes = new Uint8Array(binary.length);
    for (var i = 0; i < binary.length; i++) {
      bytes[i] = binary.charCodeAt(i);
    }
    return bytes;
  }
  window.__hopalBioV2 = {
    isAvailable: async function () {
      try {
        return !!(window.isSecureContext && window.PublicKeyCredential && navigator.credentials && navigator.credentials.create);
      } catch (e) {
        return false;
      }
    },
    register: async function (userId, userName) {
      if (!window.isSecureContext || !window.PublicKeyCredential || !navigator.credentials) {
        return 'ERR:UNSUPPORTED';
      }
      var challenge = new Uint8Array(32);
      window.crypto.getRandomValues(challenge);
      var userBytes = new TextEncoder().encode(userId || 'hopal-user');
      var rpObj = { name: 'HOPAL - חופ"ל', id: window.location.hostname };
      var userObj = {
        id: userBytes,
        name: userName || 'חופ"ל',
        displayName: userName || 'חופ"ל'
      };
      var pubKeyCredParams = [
        { type: 'public-key', alg: -7 },
        { type: 'public-key', alg: -257 }
      ];
      try {
        var credential = await navigator.credentials.create({
          publicKey: {
            challenge: challenge,
            rp: rpObj,
            user: userObj,
            pubKeyCredParams: pubKeyCredParams,
            authenticatorSelection: {
              authenticatorAttachment: 'platform',
              userVerification: 'required',
              residentKey: 'preferred'
            },
            timeout: 60000
          }
        });
        if (credential && credential.rawId) {
          return 'OK:' + toBase64Url(credential.rawId);
        }
        return 'ERR:EMPTY';
      } catch (firstErr) {
        var errName = (firstErr && firstErr.name) ? firstErr.name : 'UnknownError';
        if (errName === 'NotSupportedError' || errName === 'InvalidStateError' || errName === 'ConstraintError') {
          try {
            var retryChallenge = new Uint8Array(32);
            window.crypto.getRandomValues(retryChallenge);
            var fallbackCred = await navigator.credentials.create({
              publicKey: {
                challenge: retryChallenge,
                rp: rpObj,
                user: userObj,
                pubKeyCredParams: pubKeyCredParams,
                authenticatorSelection: {
                  userVerification: 'required'
                },
                timeout: 60000
              }
            });
            if (fallbackCred && fallbackCred.rawId) {
              return 'OK:' + toBase64Url(fallbackCred.rawId);
            }
          } catch (secondErr) {
            var secondName = (secondErr && secondErr.name) ? secondErr.name : 'UnknownError';
            return 'ERR:' + secondName;
          }
        }
        return 'ERR:' + errName;
      }
    },
    authenticate: async function (credentialIdBase64Url) {
      try {
        var challenge = new Uint8Array(32);
        window.crypto.getRandomValues(challenge);
        var publicKey = {
          challenge: challenge,
          rpId: window.location.hostname,
          userVerification: 'required',
          timeout: 60000
        };
        if (credentialIdBase64Url && credentialIdBase64Url.length > 0) {
          publicKey.allowCredentials = [
            { type: 'public-key', id: fromBase64Url(credentialIdBase64Url) }
          ];
        }
        var assertion = await navigator.credentials.get({ publicKey: publicKey });
        return !!assertion;
      } catch (e) {
        return false;
      }
    }
  };
})();
''';
  try {
    _jsEval(script.toJS);
    _bridgeInitialized = true;
  } catch (_) {}
}

Future<bool> webBiometricsIsAvailable() async {
  try {
    _ensureBridgeInstalled();
    final res = await _jsIsAvailable().toDart;
    return res.toDart;
  } catch (_) {
    return false;
  }
}

/// Returns `'OK:<credentialId>'` or `'ERR:<errorName>'`.
Future<String> webBiometricsRegister(String userId, String userName) async {
  try {
    _ensureBridgeInstalled();
    final res = await _jsRegister(userId.toJS, userName.toJS).toDart;
    return res.toDart;
  } catch (_) {
    return 'ERR:EXCEPTION';
  }
}

Future<bool> webBiometricsAuthenticate(String credentialId) async {
  try {
    _ensureBridgeInstalled();
    final res = await _jsAuthenticate(credentialId.toJS).toDart;
    return res.toDart;
  } catch (_) {
    return false;
  }
}
