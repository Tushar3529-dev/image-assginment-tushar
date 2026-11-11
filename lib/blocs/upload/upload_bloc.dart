import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:image_picker/image_picker.dart';

import '../../repositories/image_repository.dart';
import '../../services/cloudinary_service.dart';
import 'upload_event.dart';
import 'upload_state.dart';

export 'upload_event.dart';
export 'upload_state.dart';

/// Signature of the picker call, so tests can replace [ImagePicker].
typedef PickImageFn = Future<XFile?> Function(ImageSource source);

class UploadBloc extends Bloc<UploadEvent, UploadState> {
  UploadBloc({
    required CloudinaryService cloudinaryService,
    required ImageRepository imageRepository,
    PickImageFn? pickImage,
    this.successHold = const Duration(milliseconds: 900),
  }) : _cloudinary = cloudinaryService,
       _repository = imageRepository,
       _pickImage = pickImage ?? _defaultPicker,
       super(const UploadState()) {
    on<ImagePickRequested>(_onPickRequested, transformer: droppable());
    on<ImageCleared>(_onCleared);
    on<UploadSubmitted>(_onSubmitted, transformer: droppable());
  }

  final CloudinaryService _cloudinary;
  final ImageRepository _repository;
  final PickImageFn _pickImage;

  /// How long the success state stays up (so the UI can show its check mark)
  /// before the bloc resets to initial.
  final Duration successHold;

  static Future<XFile?> _defaultPicker(ImageSource source) =>
      ImagePicker().pickImage(source: source, imageQuality: 80, maxWidth: 1600);

  Future<void> _onPickRequested(
    ImagePickRequested event,
    Emitter<UploadState> emit,
  ) async {
    final XFile? picked;
    try {
      picked = await _pickImage(event.source);
    } catch (e) {
      emit(
        state.copyWith(
          status: UploadStatus.failure,
          errorMessage: () => event.source == ImageSource.camera
              ? 'Could not open the camera.'
              : 'Could not open the gallery.',
        ),
      );
      return;
    }
    if (picked == null) return; // cancelled: no state change
    emit(
      UploadState(status: UploadStatus.picked, pickedFile: File(picked.path)),
    );
  }

  void _onCleared(ImageCleared event, Emitter<UploadState> emit) {
    emit(const UploadState());
  }

  Future<void> _onSubmitted(
    UploadSubmitted event,
    Emitter<UploadState> emit,
  ) async {
    final file = state.pickedFile;
    if (file == null) return;

    final name = event.referenceName.trim();
    if (name.isEmpty) {
      emit(
        state.copyWith(
          status: UploadStatus.failure,
          errorMessage: () => 'Please enter a reference name',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: UploadStatus.uploading,
        progress: 0,
        errorMessage: () => null,
      ),
    );
    try {
      var lastReported = 0.0;
      final result = await _cloudinary.uploadImage(
        file,
        onProgress: (fraction) {
          // Throttle to ~2% steps so a big image doesn't flood the UI.
          if (emit.isDone) return;
          if (fraction - lastReported < 0.02 && fraction < 1) return;
          lastReported = fraction;
          emit(state.copyWith(progress: fraction));
        },
      );
      await _repository.addImage(
        referenceName: name,
        imageUrl: result.url,
        publicId: result.publicId,
      );
      emit(
        UploadState(
          status: UploadStatus.success,
          pickedFile: file,
          lastUploadedName: name,
          progress: 1,
        ),
      );
      await Future<void>.delayed(successHold);
      if (!emit.isDone) emit(const UploadState());
    } catch (e) {
      emit(
        state.copyWith(
          status: UploadStatus.failure,
          errorMessage: () => _readable(e),
        ),
      );
    }
  }

  static String _readable(Object e) {
    if (e is CloudinaryException) return e.message;
    final text = e.toString();
    if (text.contains('permission-denied')) {
      return 'Saving failed: permission denied by Firestore.';
    }
    if (text.contains('unavailable')) {
      return 'Saving failed: no connection to the server.';
    }
    return 'Something went wrong. Please try again.';
  }
}
