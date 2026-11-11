import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/upload/upload_bloc.dart';
import '../../core/app_motion.dart';
import '../../core/app_theme.dart';
import '../../router/app_routes.dart';
import '../../widgets/app_snackbar.dart';

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void dispose() {
    _nameController.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _clearAndLeave() {
    final bloc = context.read<UploadBloc>();
    if (bloc.state.isBusy) return;
    bloc.add(const ImageCleared());
    context.go(AppRoutes.upload);
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<UploadBloc>().add(UploadSubmitted(_nameController.text));
  }

  void _listener(BuildContext context, UploadState state) {
    switch (state.status) {
      case UploadStatus.success:
        HapticFeedback.lightImpact();
        showAppSnackBar(
          context,
          "'${state.lastUploadedName}' uploaded successfully",
        );
        _nameController.clear();
      case UploadStatus.failure:
        showAppSnackBar(
          context,
          state.errorMessage ?? 'Upload failed',
          isError: true,
        );
        if (_nameController.text.trim().isEmpty &&
            !AppMotion.reduced(context)) {
          _shake.forward(from: 0);
        }
      case UploadStatus.initial:
        // After the success check has shown, go back to the pick screen.
        context.go(AppRoutes.upload);
      case UploadStatus.picked:
      case UploadStatus.uploading:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final uploadBloc = context.read<UploadBloc>();
    final medium = AppMotion.of(context, AppMotion.medium);

    return BlocConsumer<UploadBloc, UploadState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: _listener,
      builder: (context, state) {
        final file = state.pickedFile;
        final busy = state.isBusy;
        // Android back / iOS edge swipe behave like the ❌ button: the route
        // pops back to /upload and the picked image is cleared. Blocked while
        // an upload is running. (canPop: false would also disable the iOS
        // swipe gesture entirely, so we let the pop happen and react to it.)
        return PopScope(
          canPop: !busy,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) uploadBloc.add(const ImageCleared());
          },
          child: Scaffold(
            body: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: screenHeight * 0.6,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (file != null)
                          Image.file(
                            file,
                            fit: BoxFit.cover,
                            frameBuilder: (context, child, frame, sync) => sync
                                ? child
                                : AnimatedOpacity(
                                    opacity: frame == null ? 0 : 1,
                                    duration: medium,
                                    child: child,
                                  ),
                          )
                        else
                          const ColoredBox(color: AppColors.placeholder),
                        IgnorePointer(
                          child: AnimatedOpacity(
                            opacity: busy ? 1 : 0,
                            duration: medium,
                            child: const ColoredBox(color: Color(0x33000000)),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: AnimatedOpacity(
                            opacity: busy ? 0.4 : 1,
                            duration: medium,
                            child: Material(
                              color: AppColors.error,
                              shape: const CircleBorder(),
                              elevation: 2,
                              child: IconButton(
                                tooltip: 'Remove image',
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: busy ? null : _clearAndLeave,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _UploadProgressBar(
                            visible: busy,
                            value: state.progress,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _shake,
                          builder: (context, child) => Transform.translate(
                            offset: Offset(
                              math.sin(_shake.value * math.pi * 6) *
                                  10 *
                                  (1 - _shake.value),
                              0,
                            ),
                            child: child,
                          ),
                          child: TextField(
                            controller: _nameController,
                            enabled: !busy,
                            textInputAction: TextInputAction.done,
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: (_) => _submit(),
                            decoration: const InputDecoration(
                              hintText: 'Reference Name',
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SubmitButton(
                          state: state,
                          onPressed: busy ? null : _submit,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Thin bar along the bottom edge of the photo, driven by real upload bytes.
class _UploadProgressBar extends StatelessWidget {
  const _UploadProgressBar({required this.visible, required this.value});

  final bool visible;
  final double value;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: AppMotion.of(context, AppMotion.medium),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: visible ? value : 0),
        duration: AppMotion.of(context, const Duration(milliseconds: 250)),
        builder: (context, progress, _) => LinearProgressIndicator(
          value: progress,
          minHeight: 4,
          color: AppColors.primary,
          backgroundColor: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// Submit → "Uploading 42%" with a spinner → a green circle with a check.
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.state, required this.onPressed});

  final UploadState state;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final done = state.status == UploadStatus.success;
    final uploading = state.isUploading;
    final width = done
        ? 56.0
        : uploading
        ? 210.0
        : 180.0;

    final Widget label;
    if (done) {
      label = const Icon(
        Icons.check_rounded,
        key: ValueKey('done'),
        color: Colors.white,
        size: 30,
      );
    } else if (uploading) {
      final percent = (state.progress * 100).round();
      label = Row(
        key: const ValueKey('uploading'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            state.progress >= 1 ? 'Saving…' : 'Uploading $percent%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      );
    } else {
      label = const Text(
        'Submit',
        key: ValueKey('idle'),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      );
    }

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: done ? 'Uploaded' : null,
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.medium),
        curve: Curves.easeOutCubic,
        width: width,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onPressed,
            child: Center(
              child: AnimatedSwitcher(
                duration: AppMotion.of(context, AppMotion.fast),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: label,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
