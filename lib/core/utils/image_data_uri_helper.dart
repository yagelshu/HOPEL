import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

/// Encodes image bytes into persistent `data:image/...;base64,...` URIs so photos
/// survive reloads and device switches on Web/PWA without ephemeral `blob:` URLs.
class ImageDataUriHelper {
  static String encodeBytesToDataUri(
    Uint8List bytes, {
    String mimeType = 'image/jpeg',
  }) {
    if (bytes.isEmpty) return '';
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  /// Infers MIME type from filename or picks an appropriate default.
  static String inferMimeType(String? filenameOrPath) {
    final lower = (filenameOrPath ?? '').toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  /// True only for native local filesystem paths (not Web `blob:` / `data:` / HTTP URLs).
  static bool isLocalFilesystemPath(String? path) {
    if (path == null) return false;
    final trimmed = path.trim();
    if (trimmed.isEmpty) return false;
    return !trimmed.startsWith('data:') &&
        !trimmed.startsWith('blob:') &&
        !trimmed.startsWith('http://') &&
        !trimmed.startsWith('https://');
  }

  /// Picks and resizes an image, returning a portable base64 Data URI string.
  static Future<String?> pickAsDataUri(
    ImagePicker picker,
    ImageSource source, {
    double maxWidth = 720,
    double maxHeight = 720,
    int imageQuality = 72,
  }) async {
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
    if (pickedFile == null) return null;
    final bytes = await pickedFile.readAsBytes();
    if (bytes.isEmpty) return null;
    return encodeBytesToDataUri(
      bytes,
      mimeType: inferMimeType(pickedFile.name.isNotEmpty ? pickedFile.name : pickedFile.path),
    );
  }
}

