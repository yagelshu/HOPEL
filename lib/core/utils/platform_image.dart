import 'package:flutter/material.dart';
import 'platform_image_io.dart'
    if (dart.library.html) 'platform_image_web.dart'
    if (dart.library.js_interop) 'platform_image_web.dart';

/// Safely creates an [ImageProvider] for both local file paths (mobile/desktop)
/// and blob/network URLs (Flutter Web), preventing `dart:io` `File` crashes on Web.
ImageProvider resolveLocalOrWebImage(String path) => createPlatformImageProvider(path);

