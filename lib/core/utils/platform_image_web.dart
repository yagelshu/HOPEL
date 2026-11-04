import 'package:flutter/material.dart';

ImageProvider createPlatformImageProvider(String path) {
  return NetworkImage(path);
}

