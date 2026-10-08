import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';

void main() async {
  var staticHandler = createStaticHandler('build/web', defaultDocument: 'index.html');
  
  var handler = const Pipeline().addHandler((Request request) async {
    final path = request.url.path;
    
    // Check if the request is for learning_materials
    if (path.contains('learning_materials')) {
      // Decode the URL (Flutter web might double or triple encode it)
      String decoded = path;
      while (decoded.contains('%')) {
        decoded = Uri.decodeFull(decoded);
      }
      
      final fileName = decoded.split('/').last;
      
      // Serve from the ORIGINAL assets directory (no long paths)
      final file = File('assets/learning_materials/$fileName');
      
      if (await file.exists()) {
        return Response.ok(file.openRead(), headers: {
          'Content-Type': 'application/pdf',
          'Access-Control-Allow-Origin': '*'
        });
      }
      print('404 Not Found: ${file.path}');
    }
    
    // For everything else, serve the production web build
    return staticHandler(request);
  });

  var server = await io.serve(handler, '0.0.0.0', 8080);
  print('Custom Server serving at http://${server.address.host}:${server.port}');
}
