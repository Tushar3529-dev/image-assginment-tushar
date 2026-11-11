import 'package:equatable/equatable.dart';

sealed class ImagesEvent extends Equatable {
  const ImagesEvent();

  @override
  List<Object?> get props => [];
}

final class ImagesSubscriptionRequested extends ImagesEvent {
  const ImagesSubscriptionRequested();
}
