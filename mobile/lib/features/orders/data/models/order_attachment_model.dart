import 'package:equatable/equatable.dart';
import 'package:mongez/core/constants/api_constants.dart';

class OrderAttachmentModel extends Equatable {
  final int id;
  final String kind;          // "image" | "audio" | "video"
  final String? fileUrl;
  final String? caption;
  final int? durationSeconds;
  final int? sizeBytes;
  final String? createdAt;

  const OrderAttachmentModel({
    required this.id,
    required this.kind,
    this.fileUrl,
    this.caption,
    this.durationSeconds,
    this.sizeBytes,
    this.createdAt,
  });

  factory OrderAttachmentModel.fromJson(Map<String, dynamic> json) =>
      OrderAttachmentModel(
        id: json['id'] as int,
        kind: (json['kind'] as String?) ?? 'image',
        fileUrl: _absoluteUrl(json['file_url'] as String?),
        caption: json['caption'] as String?,
        durationSeconds: json['duration_seconds'] as int?,
        sizeBytes: json['size_bytes'] as int?,
        createdAt: json['created_at'] as String?,
      );

  bool get isImage => kind == 'image';
  bool get isAudio => kind == 'audio';
  bool get isVideo => kind == 'video';

  /// If the backend returned a relative `/media/...` path (no request context
  /// during serialization), prepend the API host so Image.network and
  /// audioplayers can fetch it.
  static String? _absoluteUrl(String? raw) {
    if (raw == null || raw.isEmpty) return raw;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    // Strip `/api/` suffix from baseUrl so /media/... lands on the host root.
    final base = ApiConstants.baseUrl;
    final hostEnd = base.endsWith('/api/')
        ? base.length - 'api/'.length
        : base.length;
    final host = base.substring(0, hostEnd).replaceAll(RegExp(r'/+$'), '');
    final path = raw.startsWith('/') ? raw : '/$raw';
    return '$host$path';
  }

  @override
  List<Object?> get props => [id, kind, fileUrl, caption, durationSeconds, sizeBytes];
}
