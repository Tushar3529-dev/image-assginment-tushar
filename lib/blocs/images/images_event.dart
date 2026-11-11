import 'package:equatable/equatable.dart';

import '../../models/image_item.dart';

sealed class ImagesEvent extends Equatable {
  const ImagesEvent();

  @override
  List<Object?> get props => [];
}

final class ImagesSubscriptionRequested extends ImagesEvent {
  const ImagesSubscriptionRequested();
}

/// The user chose "Delete photo" and confirmed.
final class ImageDeleteRequested extends ImagesEvent {
  const ImageDeleteRequested(this.image);
  final ImageItem image;

  @override
  List<Object?> get props => [image.id];
}
