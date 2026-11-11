import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_assignment/blocs/upload/upload_bloc.dart';
import 'package:image_assignment/repositories/image_repository.dart';
import 'package:image_assignment/services/cloudinary_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

class MockCloudinaryService extends Mock implements CloudinaryService {}

class MockImageRepository extends Mock implements ImageRepository {}

void main() {
  late MockCloudinaryService cloudinary;
  late MockImageRepository repository;
  final file = File('/tmp/test.jpg');
  final pickedState = UploadState(
    status: UploadStatus.picked,
    pickedFile: file,
  );

  setUpAll(() => registerFallbackValue(File('')));

  setUp(() {
    cloudinary = MockCloudinaryService();
    repository = MockImageRepository();
    when(
      () => repository.addImage(
        referenceName: any(named: 'referenceName'),
        imageUrl: any(named: 'imageUrl'),
        publicId: any(named: 'publicId'),
      ),
    ).thenAnswer((_) async {});
  });

  UploadBloc build({PickImageFn? pick}) => UploadBloc(
    cloudinaryService: cloudinary,
    imageRepository: repository,
    pickImage: pick ?? (_) async => null,
    successHold: Duration.zero,
  );

  void stubUpload({List<double> progress = const []}) {
    when(
      () => cloudinary.uploadImage(any(), onProgress: any(named: 'onProgress')),
    ).thenAnswer((invocation) async {
      final report = invocation.namedArguments[#onProgress] as UploadProgress?;
      progress.forEach(report ?? (_) {});
      return (url: 'https://x/y.jpg', publicId: 'nap_images/y');
    });
  }

  group('UploadBloc', () {
    blocTest<UploadBloc, UploadState>(
      'picking an image emits picked with the file',
      build: () => build(pick: (_) async => XFile(file.path)),
      act: (b) => b.add(const ImagePickRequested(ImageSource.gallery)),
      expect: () => [pickedState],
    );

    blocTest<UploadBloc, UploadState>(
      'cancelled pick emits nothing',
      build: build,
      act: (b) => b.add(const ImagePickRequested(ImageSource.gallery)),
      expect: () => <UploadState>[],
    );

    blocTest<UploadBloc, UploadState>(
      'empty name emits failure and keeps the file',
      build: build,
      seed: () => pickedState,
      act: (b) => b.add(const UploadSubmitted('   ')),
      expect: () => [
        UploadState(
          status: UploadStatus.failure,
          pickedFile: file,
          errorMessage: 'Please enter a reference name',
        ),
      ],
      verify: (_) => verifyNever(
        () =>
            cloudinary.uploadImage(any(), onProgress: any(named: 'onProgress')),
      ),
    );

    blocTest<UploadBloc, UploadState>(
      'success path emits uploading, success, then initial',
      setUp: stubUpload,
      build: build,
      seed: () => pickedState,
      act: (b) => b.add(const UploadSubmitted('  Test 1 ')),
      wait: const Duration(milliseconds: 10),
      expect: () => [
        UploadState(status: UploadStatus.uploading, pickedFile: file),
        UploadState(
          status: UploadStatus.success,
          pickedFile: file,
          lastUploadedName: 'Test 1',
          progress: 1,
        ),
        const UploadState(),
      ],
      verify: (_) => verify(
        () => repository.addImage(
          referenceName: 'Test 1',
          imageUrl: 'https://x/y.jpg',
          publicId: 'nap_images/y',
        ),
      ).called(1),
    );

    blocTest<UploadBloc, UploadState>(
      'upload progress is reported, throttled to 2% steps',
      setUp: () => stubUpload(progress: [0.005, 0.5, 0.51, 1.0]),
      build: build,
      seed: () => pickedState,
      act: (b) => b.add(const UploadSubmitted('Test 1')),
      wait: const Duration(milliseconds: 10),
      expect: () => [
        UploadState(status: UploadStatus.uploading, pickedFile: file),
        UploadState(
          status: UploadStatus.uploading,
          pickedFile: file,
          progress: 0.5,
        ),
        UploadState(
          status: UploadStatus.uploading,
          pickedFile: file,
          progress: 1,
        ),
        UploadState(
          status: UploadStatus.success,
          pickedFile: file,
          lastUploadedName: 'Test 1',
          progress: 1,
        ),
        const UploadState(),
      ],
    );

    blocTest<UploadBloc, UploadState>(
      'service error emits failure with a readable message, keeps the file',
      setUp: () {
        when(
          () => cloudinary.uploadImage(
            any(),
            onProgress: any(named: 'onProgress'),
          ),
        ).thenThrow(
          const CloudinaryException('Upload failed (400): Bad preset'),
        );
      },
      build: build,
      seed: () => pickedState,
      act: (b) => b.add(const UploadSubmitted('Test 1')),
      expect: () => [
        UploadState(status: UploadStatus.uploading, pickedFile: file),
        UploadState(
          status: UploadStatus.failure,
          pickedFile: file,
          errorMessage: 'Upload failed (400): Bad preset',
        ),
      ],
    );

    blocTest<UploadBloc, UploadState>(
      'ImageCleared resets to initial',
      build: build,
      seed: () => pickedState,
      act: (b) => b.add(const ImageCleared()),
      expect: () => [const UploadState()],
    );
  });
}
