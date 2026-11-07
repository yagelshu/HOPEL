import 'dart:io';
import 'package:flutter/material.dart';

ImageProvider createPlatformImageProvider(String path) {
  if (path.startsWith('data:')) {
    final uriData = UriData.parse(path);
    return MemoryImage(uriData.contentAsBytes());
  }
  if (path.startsWith('http://') ||
      path.startsWith('https://') ||
      path.startsWith('blob:')) {
    return NetworkImage(path);
  }
  return FileImage(File(path));
}
