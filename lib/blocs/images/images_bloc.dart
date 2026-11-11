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
  }

  final ImageRepository _repository;

  Future<void> _onSubscriptionRequested(
    ImagesSubscriptionRequested event,
    Emitter<ImagesState> emit,
  ) async {
    await emit.forEach(
      _repository.watchImages(),
      onData: (images) =>
          ImagesState(status: ImagesStatus.loaded, images: images),
      onError: (error, _) => state.copyWith(
        status: ImagesStatus.failure,
        errorMessage: 'Could not load images: $error',
      ),
    );
  }
}
