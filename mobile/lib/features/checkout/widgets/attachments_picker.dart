import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:mongez/models/picked_attachment.dart';
import 'package:mongez/services/image_picker_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Mic recording is only wired for mobile + macOS — on Linux/Windows the
/// permission_handler plugin has no native implementation and would throw
/// MissingPluginException. Web is also excluded for now.
bool get _audioRecordingSupported {
  if (kIsWeb) return false;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return true;
    default:
      return false;
  }
}

/// Snapshot exposed to the parent — list of picked photos + an optional
/// audio path (native-only, since recording is gated above).
class AttachmentBundle {
  final List<PickedAttachment> photos;
  final String? audioPath;
  final int? audioDurationSeconds;

  const AttachmentBundle({
    this.photos = const [],
    this.audioPath,
    this.audioDurationSeconds,
  });

  bool get isEmpty => photos.isEmpty && (audioPath?.isEmpty ?? true);
}

class AttachmentsPicker extends StatefulWidget {
  /// Called whenever the bundle changes — the parent should hold the latest.
  final ValueChanged<AttachmentBundle> onChanged;
  const AttachmentsPicker({super.key, required this.onChanged});

  @override
  State<AttachmentsPicker> createState() => _AttachmentsPickerState();
}

class _AttachmentsPickerState extends State<AttachmentsPicker> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  final List<PickedAttachment> _photos = [];
  String? _audioPath;
  int? _audioDurationSeconds;
  bool _isRecording = false;
  bool _isPlaying = false;
  Timer? _recordTimer;
  int _recordSeconds = 0;

  @override
  void dispose() {
    _recordTimer?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(AttachmentBundle(
      photos: List.unmodifiable(_photos),
      audioPath: _audioPath,
      audioDurationSeconds: _audioDurationSeconds,
    ));
  }

  Future<void> _pickFromCamera() async {
    try {
      final picked = await ImagePickerService.pickOne(fromCamera: true);
      if (picked != null) {
        setState(() => _photos.add(picked));
        _emit();
      }
    } on MissingPluginException catch (_) {
      _showError('Camera not supported on this platform');
    } catch (e) {
      _showError('Could not open camera: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final remaining = 5 - _photos.length;
      final files = await ImagePickerService.pickMulti(limit: remaining);
      if (files.isNotEmpty) {
        setState(() => _photos.addAll(files.take(remaining)));
        _emit();
      }
    } on MissingPluginException catch (_) {
      _showError('Gallery not supported on this platform');
    } catch (e) {
      _showError('Could not open gallery: $e');
    }
  }

  void _removePhoto(int idx) {
    setState(() => _photos.removeAt(idx));
    _emit();
  }

  Future<void> _toggleRecord() async {
    if (!_audioRecordingSupported) {
      _showError('Audio recording is not supported on this platform');
      return;
    }

    if (_isRecording) {
      final path = await _recorder.stop();
      _recordTimer?.cancel();
      setState(() {
        _isRecording = false;
        if (path != null) {
          _audioPath = path;
          _audioDurationSeconds = _recordSeconds;
        }
      });
      _emit();
      return;
    }

    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        _showError('Microphone permission denied');
        return;
      }
    } on MissingPluginException catch (_) {
      _showError('Audio recording is not supported on this platform');
      return;
    } catch (_) {
      _showError('Microphone permission unavailable');
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/order_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    try {
      await _recorder.start(const RecordConfig(), path: path);
      setState(() {
        _isRecording = true;
        _recordSeconds = 0;
      });
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _recordSeconds++);
        if (_recordSeconds >= 120) _toggleRecord(); // cap at 2 min
      });
    } catch (e) {
      _showError('Could not start recording');
    }
  }

  Future<void> _togglePlay() async {
    if (_audioPath == null) return;
    if (_isPlaying) {
      await _player.stop();
      setState(() => _isPlaying = false);
      return;
    }
    setState(() => _isPlaying = true);
    await _player.play(DeviceFileSource(_audioPath!));
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  void _removeAudio() {
    setState(() {
      _audioPath = null;
      _audioDurationSeconds = null;
    });
    _emit();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  String _fmtDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Action row
        Row(
          children: [
            _ActionChip(
              icon: Icons.photo_camera_outlined,
              label: 'Camera',
              onTap: _photos.length < 5 ? _pickFromCamera : null,
            ),
            const SizedBox(width: 8),
            const SizedBox(width: 8),
            _ActionChip(
              icon: Icons.photo_library_outlined,
              label: 'Gallery',
              onTap: _photos.length < 5 ? _pickFromGallery : null,
            ),
            const SizedBox(width: 8),
            _ActionChip(
              icon: _isRecording ? Icons.stop_rounded : Icons.mic_none_rounded,
              label: _isRecording
                  ? _fmtDuration(_recordSeconds)
                  : (_audioPath != null ? 'Re-record' : 'Record'),
              onTap: _audioRecordingSupported ? _toggleRecord : null,
              tint: _isRecording ? cs.error : null,
              recording: _isRecording,
            ),
          ],
        ),
        if (_photos.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(
                        _photos[i].bytes,
                        width: 88, height: 88, fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -6, right: -6,
                      child: InkWell(
                        onTap: () => _removePhoto(i),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cs.error, shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                            ],
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
        if (_audioPath != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: _togglePlay,
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.primary, shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      color: Colors.white, size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Voice note', style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
                      if (_audioDurationSeconds != null)
                        Text(_fmtDuration(_audioDurationSeconds!),
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.6),
                            )),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: cs.error),
                  onPressed: _removeAudio,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? tint;
  final bool recording;
  const _ActionChip({
    required this.icon,
    required this.label,
    this.onTap,
    this.tint,
    this.recording = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disabled = onTap == null;
    final color = tint ?? cs.primary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: recording
                ? color.withValues(alpha: 0.15)
                : color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: recording
                  ? color
                  : color.withValues(alpha: 0.22),
              width: recording ? 1.6 : 1.2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: disabled ? cs.onSurface.withValues(alpha: 0.4) : color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: disabled ? cs.onSurface.withValues(alpha: 0.4) : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
