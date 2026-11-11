import 'dart:io';

import 'package:equatable/equatable.dart';

enum UploadStatus { initial, picked, uploading, success, failure }

class UploadState extends Equatable {
  const UploadState({
    this.status = UploadStatus.initial,
    this.pickedFile,
    this.errorMessage,
    this.lastUploadedName,
  });

  final UploadStatus status;
  final File? pickedFile;
  final String? errorMessage;
  final String? lastUploadedName;

  bool get isUploading => status == UploadStatus.uploading;

  /// Nullable fields are passed as closures so they can be set to null.
  UploadState copyWith({
    UploadStatus? status,
    File? Function()? pickedFile,
    String? Function()? errorMessage,
    String? Function()? lastUploadedName,
  }) {
    return UploadState(
      status: status ?? this.status,
      pickedFile: pickedFile != null ? pickedFile() : this.pickedFile,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      lastUploadedName: lastUploadedName != null
          ? lastUploadedName()
          : this.lastUploadedName,
    );
  }

  @override
  List<Object?> get props => [
    status,
    pickedFile?.path,
    errorMessage,
    lastUploadedName,
  ];
}
