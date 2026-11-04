import 'dart:js_interop';

@JS('hopalBiometrics.isAvailable')
external JSPromise<JSBoolean> _jsIsAvailable();

@JS('hopalBiometrics.register')
external JSPromise<JSString?> _jsRegister(JSString userId, JSString userName);

@JS('hopalBiometrics.authenticate')
external JSPromise<JSBoolean> _jsAuthenticate(JSString credentialId);

Future<bool> webBiometricsIsAvailable() async {
  try {
    final res = await _jsIsAvailable().toDart;
    return res.toDart;
  } catch (_) {
    return false;
  }
}

Future<String?> webBiometricsRegister(String userId, String userName) async {
  try {
    final res = await _jsRegister(userId.toJS, userName.toJS).toDart;
    return res?.toDart;
  } catch (_) {
    return null;
  }
}

Future<bool> webBiometricsAuthenticate(String credentialId) async {
  try {
    final res = await _jsAuthenticate(credentialId.toJS).toDart;
    return res.toDart;
  } catch (_) {
    return false;
  }
}
