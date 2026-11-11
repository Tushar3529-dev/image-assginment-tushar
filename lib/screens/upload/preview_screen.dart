import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/upload/upload_bloc.dart';
import '../../core/app_theme.dart';
import '../../router/app_routes.dart';

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _clearAndLeave() {
    final bloc = context.read<UploadBloc>();
    if (bloc.state.isUploading) return;
    bloc.add(const ImageCleared());
    context.go(AppRoutes.upload);
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<UploadBloc>().add(UploadSubmitted(_nameController.text));
  }

  void _listener(BuildContext context, UploadState state) {
    final messenger = ScaffoldMessenger.of(context);
    switch (state.status) {
      case UploadStatus.success:
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: AppColors.primary,
              content: Text(
                "'${state.lastUploadedName}' uploaded successfully",
              ),
            ),
          );
        _nameController.clear();
        context.go(AppRoutes.upload);
      case UploadStatus.failure:
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              content: Text(state.errorMessage ?? 'Upload failed'),
            ),
          );
      case UploadStatus.initial:
      case UploadStatus.picked:
      case UploadStatus.uploading:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    final uploadBloc = context.read<UploadBloc>();

    return BlocConsumer<UploadBloc, UploadState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: _listener,
      builder: (context, state) {
        final file = state.pickedFile;
        final uploading = state.isUploading;
        // Android back / iOS edge swipe behave like the ❌ button: the route
        // pops back to /upload and the picked image is cleared. Blocked while
        // an upload is running. (canPop: false would also disable the iOS
        // swipe gesture entirely, so we let the pop happen and react to it.)
        return PopScope(
          canPop: !uploading,
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
                          Image.file(file, fit: BoxFit.cover)
                        else
                          const ColoredBox(color: AppColors.placeholder),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Material(
                            color: uploading
                                ? AppColors.error.withValues(alpha: 0.5)
                                : AppColors.error,
                            shape: const CircleBorder(),
                            elevation: 2,
                            child: IconButton(
                              tooltip: 'Remove image',
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: uploading ? null : _clearAndLeave,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          enabled: !uploading,
                          textInputAction: TextInputAction.done,
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(
                            hintText: 'Reference Name',
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: 180,
                          height: 48,
                          child: FilledButton(
                            onPressed: uploading ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              disabledBackgroundColor: AppColors.primary
                                  .withValues(alpha: 0.6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: uploading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Submit',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
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
