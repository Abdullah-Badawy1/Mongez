import 'package:flutter/foundation.dart';

/// A file the user picked or recorded, captured as raw bytes so the
/// upload path is identical on web (where `dart:io.File` is unavailable
/// and `image_picker` returns `blob://` URLs) and on native.
///
/// `path` is set on native only — handy for things like `DeviceFileSource`
/// audio playback before submission. Anything that needs the file
/// content should always read from `bytes`.
class PickedAttachment {
  final String name;
  final Uint8List bytes;
  final String? path;

  const PickedAttachment({
    required this.name,
    required this.bytes,
    this.path,
  });

  int get size => bytes.length;
}
