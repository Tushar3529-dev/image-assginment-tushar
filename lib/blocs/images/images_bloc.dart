import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../../repositories/image_repository.dart';
import 'images_event.dart';
import 'images_state.dart';

export 'images_event.dart';
export 'images_state.dart';

/// Holds one long-lived subscription to the Firestore `images` collection.
/// Every snapshot (add/delete anywhere) becomes a new [ImagesState].
class ImagesBloc extends Bloc<ImagesEvent, ImagesState> {
  ImagesBloc(this._repository) : super(const ImagesState()) {
    on<ImagesSubscriptionRequested>(
      _onSubscriptionRequested,
      transformer: restartable(),
    );
    on<ImageDeleteRequested>(_onDeleteRequested);
  }

  final ImageRepository _repository;
  int _noticeId = 0;

  Future<void> _onSubscriptionRequested(
    ImagesSubscriptionRequested event,
    Emitter<ImagesState> emit,
  ) async {
    await emit.forEach(
      _repository.watchImages(),
      onData: (images) =>
          state.copyWith(status: ImagesStatus.loaded, images: images),
      onError: (error, _) => state.copyWith(
        status: ImagesStatus.failure,
        errorMessage: 'Could not load images: $error',
      ),
    );
  }

  Future<void> _onDeleteRequested(
    ImageDeleteRequested event,
    Emitter<ImagesState> emit,
  ) async {
    final image = event.image;
    if (state.deletingIds.contains(image.id)) return;
    emit(state.copyWith(deletingIds: {...state.deletingIds, image.id}));
    try {
      await _repository.deleteImage(image.id);
      emit(
        state.copyWith(
          deletingIds: {...state.deletingIds}..remove(image.id),
          notice: ImagesNotice(++_noticeId, "'${image.referenceName}' deleted"),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          deletingIds: {...state.deletingIds}..remove(image.id),
          notice: ImagesNotice(
            ++_noticeId,
            "Couldn't delete '${image.referenceName}'. Try again.",
            isError: true,
          ),
        ),
      );
    }
  }
}
