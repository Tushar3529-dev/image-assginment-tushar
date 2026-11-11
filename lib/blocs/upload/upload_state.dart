import 'dart:io';

import 'package:equatable/equatable.dart';

enum UploadStatus { initial, picked, uploading, success, failure }

class UploadState extends Equatable {
  const UploadState({
    this.status = UploadStatus.initial,
    this.pickedFile,
    this.errorMessage,
    this.lastUploadedName,
    this.progress = 0,
  });

  final UploadStatus status;
  final File? pickedFile;
  final String? errorMessage;
  final String? lastUploadedName;

  /// Fraction of the image bytes sent to Cloudinary (0.0 to 1.0).
  final double progress;

  bool get isUploading => status == UploadStatus.uploading;

  /// Uploading, or showing the success check before the reset.
  bool get isBusy => isUploading || status == UploadStatus.success;

  /// Nullable fields are passed as closures so they can be set to null.
  UploadState copyWith({
    UploadStatus? status,
    File? Function()? pickedFile,
    String? Function()? errorMessage,
    String? Function()? lastUploadedName,
    double? progress,
  }) {
    return UploadState(
      status: status ?? this.status,
      pickedFile: pickedFile != null ? pickedFile() : this.pickedFile,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      lastUploadedName: lastUploadedName != null
          ? lastUploadedName()
          : this.lastUploadedName,
      progress: progress ?? this.progress,
    );
  }

  @override
  List<Object?> get props => [
    status,
    pickedFile?.path,
    errorMessage,
    lastUploadedName,
    progress,
  ];
}
