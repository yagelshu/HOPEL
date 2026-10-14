import 'package:shared_preferences/shared_preferences.dart';

/// Tiny persistent key-value store. Same implementation on web and mobile,
/// so what you test in the browser is what runs on the phone.
abstract class LocalStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
  Future<void> removeByPrefix(String prefix);
}

class PrefsLocalStore implements LocalStore {
  SharedPreferences? _prefs;
  Future<SharedPreferences> get _p async => _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<String?> read(String key) async => (await _p).getString(key);

  @override
  Future<void> write(String key, String value) async => (await _p).setString(key, value);

  @override
  Future<void> remove(String key) async => (await _p).remove(key);

  @override
  Future<void> removeByPrefix(String prefix) async {
    final p = await _p;
    for (final k in p.getKeys().where((k) => k.startsWith(prefix)).toList()) {
      await p.remove(k);
    }
  }
}

class MemoryLocalStore implements LocalStore {
  final Map<String, String> data = {};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<void> remove(String key) async => data.remove(key);

  @override
  Future<void> removeByPrefix(String prefix) async => data.removeWhere((k, _) => k.startsWith(prefix));
}
