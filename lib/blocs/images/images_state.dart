import 'package:equatable/equatable.dart';

import '../../models/image_item.dart';

enum ImagesStatus { loading, loaded, failure }

class ImagesState extends Equatable {
  const ImagesState({
    this.status = ImagesStatus.loading,
    this.images = const [],
    this.errorMessage,
  });

  final ImagesStatus status;
  final List<ImageItem> images;
  final String? errorMessage;

  ImagesState copyWith({
    ImagesStatus? status,
    List<ImageItem>? images,
    String? errorMessage,
  }) {
    return ImagesState(
      status: status ?? this.status,
      images: images ?? this.images,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, images, errorMessage];
}
