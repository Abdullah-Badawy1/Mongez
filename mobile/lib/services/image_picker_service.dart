import 'dart:io';

import 'package:file_selector/file_selector.dart' as fs;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart' as ip;

/// Platform-aware image picking.
///
/// `image_picker` has no implementation on Linux/Windows. For desktop we use
/// `file_selector` (filesystem picker) instead, which always works.
class PickedImage {
  final String path;
  final String? name;
  const PickedImage({required this.path, this.name});
}

class ImagePickerService {
  ImagePickerService._();

  static bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isLinux || Platform.isWindows || Platform.isMacOS;
  }

  static bool get supportsCamera {
    if (kIsWeb) return true;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Pick a single image. On desktop the "camera" flag is ignored (no camera
  /// integration) and a file dialog is shown instead.
  static Future<PickedImage?> pickOne({bool fromCamera = false}) async {
    if (_isDesktop) {
      const typeGroup = fs.XTypeGroup(
        label: 'images',
        extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic'],
      );
      final file = await fs.openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return null;
      return PickedImage(path: file.path, name: file.name);
    }

    final picker = ip.ImagePicker();
    final picked = await picker.pickImage(
      source: fromCamera ? ip.ImageSource.camera : ip.ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return PickedImage(path: picked.path, name: picked.name);
  }

  /// Pick multiple images (gallery only on mobile; file dialog on desktop).
  static Future<List<PickedImage>> pickMulti({int limit = 5}) async {
    if (_isDesktop) {
      const typeGroup = fs.XTypeGroup(
        label: 'images',
        extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic'],
      );
      final files = await fs.openFiles(acceptedTypeGroups: [typeGroup]);
      return files
          .take(limit)
          .map((f) => PickedImage(path: f.path, name: f.name))
          .toList();
    }

    final picker = ip.ImagePicker();
    final picked = await picker.pickMultiImage(
      imageQuality: 85, limit: limit,
    );
    return picked
        .take(limit)
        .map((f) => PickedImage(path: f.path, name: f.name))
        .toList();
  }
}
