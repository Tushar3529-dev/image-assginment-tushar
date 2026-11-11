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
      state.copyWith(status: UploadStatus.uploading, errorMessage: () => null),
    );
    try {
      final result = await _cloudinary.uploadImage(file);
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
        ),
      );
      emit(const UploadState());
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
