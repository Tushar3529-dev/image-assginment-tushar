import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../blocs/upload/upload_bloc.dart';
import '../../core/app_motion.dart';
import '../../core/app_theme.dart';
import '../../router/app_routes.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/dashed_border_box.dart';
import '../../widgets/fade_slide_in.dart';

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
          showAppSnackBar(context, state.errorMessage!, isError: true);
        }
      },
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeSlideIn(
                  child: Text(
                    'Add a photo',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 60),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 24),
                    child: Text(
                      'Pick one from your gallery or take a new one',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: DashedBorderBox(
                    height: 200,
                    animate: true,
                    fillColor: AppColors.primary.withValues(alpha: 0.05),
                    onTap: () => context.read<UploadBloc>().add(
                      const ImagePickRequested(ImageSource.gallery),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _FloatingIcon(icon: Icons.photo_library_outlined),
                        const SizedBox(height: 12),
                        Text('Browser Gallery', style: labelStyle),
                      ],
                    ),
                  ),
                ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 180),
                  child: Padding(
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
                ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 240),
                  child: DashedBorderBox(
                    height: 65,
                    animate: true,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The gallery icon bobs up and down a few pixels to invite a tap.
class _FloatingIcon extends StatefulWidget {
  const _FloatingIcon({required this.icon});

  final IconData icon;

  @override
  State<_FloatingIcon> createState() => _FloatingIconState();
}

class _FloatingIconState extends State<_FloatingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _bob.stop();
    } else if (!_bob.isAnimating) {
      _bob.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bob,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -4 * Curves.easeInOut.transform(_bob.value)),
        child: child,
      ),
      child: Icon(widget.icon, size: 56, color: AppColors.primary),
    );
  }
}
