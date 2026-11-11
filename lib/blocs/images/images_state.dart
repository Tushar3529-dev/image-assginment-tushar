import 'package:equatable/equatable.dart';

import '../../models/image_item.dart';

enum ImagesStatus { loading, loaded, failure }

/// A one-off message for the UI to show as a snackbar (e.g. "'Test 1'
/// deleted"). [id] makes two identical messages count as two notices.
class ImagesNotice extends Equatable {
  const ImagesNotice(this.id, this.message, {this.isError = false});

  final int id;
  final String message;
  final bool isError;

  @override
  List<Object?> get props => [id, message, isError];
}

class ImagesState extends Equatable {
  const ImagesState({
    this.status = ImagesStatus.loading,
    this.images = const [],
    this.errorMessage,
    this.deletingIds = const {},
    this.notice,
  });

  final ImagesStatus status;
  final List<ImageItem> images;
  final String? errorMessage;

  /// Docs with a delete in flight (their tile is dimmed and locked).
  final Set<String> deletingIds;
  final ImagesNotice? notice;

  ImagesState copyWith({
    ImagesStatus? status,
    List<ImageItem>? images,
    String? errorMessage,
    Set<String>? deletingIds,
    ImagesNotice? notice,
  }) {
    return ImagesState(
      status: status ?? this.status,
      images: images ?? this.images,
      errorMessage: errorMessage,
      deletingIds: deletingIds ?? this.deletingIds,
      notice: notice ?? this.notice,
    );
  }

  @override
  List<Object?> get props => [
    status,
    images,
    errorMessage,
    deletingIds,
    notice,
  ];
}
