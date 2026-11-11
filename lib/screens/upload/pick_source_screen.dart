import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../blocs/upload/upload_bloc.dart';
import '../../core/app_theme.dart';
import '../../router/app_routes.dart';
import '../../widgets/dashed_border_box.dart';

class PickSourceScreen extends StatelessWidget {
  const PickSourceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final labelStyle = textTheme.titleMedium?.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
    );

    return BlocListener<UploadBloc, UploadState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == UploadStatus.picked) {
          context.go(AppRoutes.uploadPreview);
        } else if (state.status == UploadStatus.failure &&
            state.pickedFile == null &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                backgroundColor: AppColors.error,
                content: Text(state.errorMessage!),
              ),
            );
        }
      },
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DashedBorderBox(
                height: 200,
                onTap: () => context.read<UploadBloc>().add(
                  const ImagePickRequested(ImageSource.gallery),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.photo_library_outlined,
                      size: 56,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text('Browser Gallery', style: labelStyle),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  children: [
                    const Expanded(child: DashedLine()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const Expanded(child: DashedLine()),
                  ],
                ),
              ),
              DashedBorderBox(
                height: 65,
                onTap: () => context.read<UploadBloc>().add(
                  const ImagePickRequested(ImageSource.camera),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.camera_alt_outlined,
                      size: 28,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Text('Open camera', style: labelStyle),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
