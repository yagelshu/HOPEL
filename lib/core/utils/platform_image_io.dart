import 'dart:io';
import 'package:flutter/material.dart';

ImageProvider createPlatformImageProvider(String path) {
  if (path.startsWith('http://') ||
      path.startsWith('https://') ||
      path.startsWith('blob:') ||
      path.startsWith('data:')) {
    return NetworkImage(path);
  }
  return FileImage(File(path));
}

