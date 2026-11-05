import 'web_biometrics_stub.dart'
    if (dart.library.js_interop) 'web_biometrics_web.dart';

class WebBiometrics {
  static Future<bool> isAvailable() => webBiometricsIsAvailable();

  /// Returns `'OK:<credentialId>'` on success, or `'ERR:<reason>'` on failure.
  static Future<String> register({
    required String userId,
    required String userName,
  }) =>
      webBiometricsRegister(userId, userName);

  static Future<bool> authenticate(String? credentialId) =>
      webBiometricsAuthenticate(credentialId ?? '');
}
