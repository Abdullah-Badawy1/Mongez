import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:image_picker/image_picker.dart';
import 'package:mongez/services/image_picker_service.dart';

class ProfileImagePicker extends StatefulWidget {
  final Uint8List? imageBytes;
  final ValueChanged<XFile?> onImagePicked;
  final bool isImageLoading;
  final double radius;

  const ProfileImagePicker({
    super.key,
    required this.imageBytes,
    required this.onImagePicked,
    this.isImageLoading = false,
    this.radius = 60,
  });

  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final picked = await ImagePickerService.pickOne(
        fromCamera: source == ImageSource.camera,
      );
      if (picked != null) {
        // Wrap in an in-memory XFile so callers (which already accept
        // XFile) keep working. `picked.path` is null on web, so we build
        // the XFile from bytes — the same shape works on native too.
        widget.onImagePicked(
          XFile.fromData(picked.bytes, name: picked.name),
        );
      }
    } on MissingPluginException catch (_) {
      _toast(context, 'Image picking is not supported on this platform');
    } catch (e) {
      _toast(context, 'Failed to pick image: ${e.toString()}');
    }
  }

  void _toast(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showPickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Profile Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _OptionButton(
                      icon: Icons.camera_alt_outlined,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _pickImage(context, ImageSource.camera);
                      },
                    ),
                    _OptionButton(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _pickImage(context, ImageSource.gallery);
                      },
                    ),
                    if (widget.imageBytes != null && !widget.isImageLoading)
                      _OptionButton(
                        icon: Icons.delete_outline,
                        label: 'Remove',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          widget.onImagePicked(null);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: widget.isImageLoading ? null : () => _showPickerOptions(context),
      child: Stack(
        children: [
          CircleAvatar(
            radius: widget.radius,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
            backgroundImage: widget.imageBytes != null
                ? MemoryImage(widget.imageBytes!)
                : null,
            child: widget.imageBytes == null
                ? Icon(
                    Icons.camera_alt,
                    size: widget.radius * 0.5,
                    color: colorScheme.primary,
                  )
                : null,
          ),
          if (widget.isImageLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SizedBox(
                    width: widget.radius * 0.5,
                    height: widget.radius * 0.5,
                    child: const CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.edit,
                size: widget.radius * 0.25,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(icon, color: colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
