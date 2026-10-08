import 'database_repository.dart';

Future<DatabaseRepository> getPlatformDatabase() async {
  throw UnsupportedError('Cannot create a database without dart:html or dart:io');
}
