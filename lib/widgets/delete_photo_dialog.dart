import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/image_item.dart';

/// Asks before deleting. Returns true only if the user taps "Delete".
Future<bool> confirmDeletePhoto(BuildContext context, ImageItem image) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 32),
      title: const Text('Delete photo?'),
      content: Text(
        "'${image.referenceName}' will be removed from the gallery on every "
        'device.',
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

enum PhotoAction { delete }

/// The ⋮ button with a "Delete photo" item. [light] draws it for dark
/// backgrounds (the viewer); otherwise it sits in a dark circle on a tile.
class PhotoMenuButton extends StatelessWidget {
  const PhotoMenuButton({
    super.key,
    required this.onDelete,
    this.light = false,
  });

  final VoidCallback onDelete;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PhotoAction>(
      tooltip: 'Photo options',
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (action) {
        if (action == PhotoAction.delete) onDelete();
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: PhotoAction.delete,
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: AppColors.error),
              SizedBox(width: 12),
              Text(
                'Delete photo',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
      child: light
          ? const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.more_vert, color: Colors.white),
            )
          : Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0x8C000000),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_vert, color: Colors.white, size: 18),
            ),
    );
  }
}
