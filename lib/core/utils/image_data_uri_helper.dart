import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

/// Detailed result of automatic image compression.
class CompressionResult {
  final String dataUri;
  final int compressedBytesLength;
  final String mimeType;
  final String? fileName;

  const CompressionResult({
    required this.dataUri,
    required this.compressedBytesLength,
    required this.mimeType,
    this.fileName,
  });

  /// Size in Kilobytes.
  int get kb => (compressedBytesLength / 1024).round();

  /// Human-readable label (e.g. "78 KB").
  String get sizeLabel => '$kb KB';
}

/// Encodes image bytes into persistent `data:image/...;base64,...` URIs so photos
/// survive reloads and device switches on Web/PWA without ephemeral `blob:` URLs,
/// applying automatic tactical compression to minimize memory and bandwidth footprint.
class ImageDataUriHelper {
  static const double defaultMaxWidth = 960;
  static const double defaultMaxHeight = 960;
  static const int defaultImageQuality = 72;

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

  /// Picks and automatically compresses an image, returning a [CompressionResult].
  static Future<CompressionResult?> pickAsDataUriWithResult(
    ImagePicker picker,
    ImageSource source, {
    double maxWidth = defaultMaxWidth,
    double maxHeight = defaultMaxHeight,
    int imageQuality = defaultImageQuality,
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

    final mime = inferMimeType(pickedFile.name.isNotEmpty ? pickedFile.name : pickedFile.path);
    final dataUri = encodeBytesToDataUri(bytes, mimeType: mime);

    return CompressionResult(
      dataUri: dataUri,
      compressedBytesLength: bytes.length,
      mimeType: mime,
      fileName: pickedFile.name.isNotEmpty ? pickedFile.name : null,
    );
  }

  /// Backward compatible: picks and compresses an image, returning a portable base64 Data URI string.
  static Future<String?> pickAsDataUri(
    ImagePicker picker,
    ImageSource source, {
    double maxWidth = defaultMaxWidth,
    double maxHeight = defaultMaxHeight,
    int imageQuality = defaultImageQuality,
  }) async {
    final res = await pickAsDataUriWithResult(
      picker,
      source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
    return res?.dataUri;
  }

  /// Picks multiple images from the gallery and automatically compresses each one.
  static Future<List<CompressionResult>> pickMultipleAsDataUri(
    ImagePicker picker, {
    double maxWidth = defaultMaxWidth,
    double maxHeight = defaultMaxHeight,
    int imageQuality = defaultImageQuality,
  }) async {
    final pickedFiles = await picker.pickMultiImage(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
    if (pickedFiles.isEmpty) return const [];

    final results = <CompressionResult>[];
    for (final file in pickedFiles) {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) continue;
      final mime = inferMimeType(file.name.isNotEmpty ? file.name : file.path);
      final dataUri = encodeBytesToDataUri(bytes, mimeType: mime);
      results.add(CompressionResult(
        dataUri: dataUri,
        compressedBytesLength: bytes.length,
        mimeType: mime,
        fileName: file.name.isNotEmpty ? file.name : null,
      ));
    }
    return results;
  }
}

