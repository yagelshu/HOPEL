import 'package:flutter/material.dart';

ImageProvider createPlatformImageProvider(String path) {
  if (path.startsWith('data:')) {
    final uriData = UriData.parse(path);
    return MemoryImage(uriData.contentAsBytes());
  }
  return NetworkImage(path);
}
