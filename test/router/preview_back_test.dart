import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_assignment/blocs/images/images_bloc.dart';
import 'package:image_assignment/blocs/upload/upload_bloc.dart';
import 'package:image_assignment/router/app_router.dart';
import 'package:image_assignment/router/app_routes.dart';
import 'package:mocktail/mocktail.dart';

class MockUploadBloc extends MockBloc<UploadEvent, UploadState>
    implements UploadBloc {}

class MockImagesBloc extends MockBloc<ImagesEvent, ImagesState>
    implements ImagesBloc {}

void main() {
  late MockUploadBloc uploadBloc;
  late MockImagesBloc imagesBloc;

  setUp(() {
    uploadBloc = MockUploadBloc();
    imagesBloc = MockImagesBloc();
    whenListen(
      imagesBloc,
      const Stream<ImagesState>.empty(),
      initialState: const ImagesState(status: ImagesStatus.loaded),
    );
    whenListen(
      uploadBloc,
      const Stream<UploadState>.empty(),
      initialState: UploadState(
        status: UploadStatus.picked,
        pickedFile: File('/tmp/none.jpg'),
      ),
    );
  });

  Future<GoRouter> pumpOnPreview(WidgetTester tester) async {
    final router = createRouter(uploadBloc);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<UploadBloc>.value(value: uploadBloc),
          BlocProvider<ImagesBloc>.value(value: imagesBloc),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.go(AppRoutes.uploadPreview);
    await tester.pumpAndSettle();
    expect(router.state.matchedLocation, AppRoutes.uploadPreview);
    return router;
  }

  testWidgets(
    'system back on preview clears the image and returns to /upload',
    (tester) async {
      final router = await pumpOnPreview(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, AppRoutes.upload);
      verify(() => uploadBloc.add(const ImageCleared())).called(1);
    },
  );

  testWidgets(
    'iOS edge swipe on preview clears the image and returns to /upload',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        final router = await pumpOnPreview(tester);
        await tester.dragFrom(const Offset(5, 300), const Offset(500, 0));
        await tester.pumpAndSettle();

        expect(router.state.matchedLocation, AppRoutes.upload);
        verify(() => uploadBloc.add(const ImageCleared())).called(1);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
