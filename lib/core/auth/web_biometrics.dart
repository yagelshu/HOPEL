import 'web_biometrics_stub.dart'
    if (dart.library.js_interop) 'web_biometrics_web.dart';

class WebBiometrics {
  static Future<bool> isAvailable() => webBiometricsIsAvailable();

  static Future<String?> register({
    required String userId,
    required String userName,
  }) =>
      webBiometricsRegister(userId, userName);

  static Future<bool> authenticate(String? credentialId) =>
      webBiometricsAuthenticate(credentialId ?? '');
}
