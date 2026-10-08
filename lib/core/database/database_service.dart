import 'database_repository.dart';
import 'database_provider.dart'
    if (dart.library.io) 'database_provider_io.dart'
    if (dart.library.html) 'database_provider_web.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseRepository? _repository;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<DatabaseRepository> get database async {
    if (_repository != null) return _repository!;
    
    _repository = await getPlatformDatabase();
    return _repository!;
  }
}
