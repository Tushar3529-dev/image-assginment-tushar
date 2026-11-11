import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

sealed class UploadEvent extends Equatable {
  const UploadEvent();

  @override
  List<Object?> get props => [];
}

final class ImagePickRequested extends UploadEvent {
  const ImagePickRequested(this.source);
  final ImageSource source;

  @override
  List<Object?> get props => [source];
}

final class ImageCleared extends UploadEvent {
  const ImageCleared();
}

final class UploadSubmitted extends UploadEvent {
  const UploadSubmitted(this.referenceName);
  final String referenceName;

  @override
  List<Object?> get props => [referenceName];
}
