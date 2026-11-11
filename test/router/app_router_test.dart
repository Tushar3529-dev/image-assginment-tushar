import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_assignment/blocs/images/images_bloc.dart';
import 'package:image_assignment/blocs/upload/upload_bloc.dart';
import 'package:image_assignment/router/app_router.dart';
import 'package:image_assignment/router/app_routes.dart';

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
  });

  Future<GoRouter> pumpRouter(WidgetTester tester) async {
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
    await tester.pumpAndSettle();
    return router;
  }

  String location(GoRouter r) =>
      r.routerDelegate.currentConfiguration.uri.toString();

  testWidgets('/upload/preview with no picked file redirects to /upload', (
    tester,
  ) async {
    whenListen(
      uploadBloc,
      const Stream<UploadState>.empty(),
      initialState: const UploadState(),
    );
    final router = await pumpRouter(tester);

    router.go(AppRoutes.uploadPreview);
    await tester.pumpAndSettle();

    expect(location(router), AppRoutes.upload);
  });

  testWidgets('/upload/preview with a picked file stays on preview', (
    tester,
  ) async {
    whenListen(
      uploadBloc,
      const Stream<UploadState>.empty(),
      initialState: UploadState(
        status: UploadStatus.picked,
        pickedFile: File('/tmp/none.jpg'),
      ),
    );
    final router = await pumpRouter(tester);

    router.go(AppRoutes.uploadPreview);
    await tester.pump();

    expect(location(router), AppRoutes.uploadPreview);
  });

  testWidgets('unknown route shows Page not found', (tester) async {
    whenListen(
      uploadBloc,
      const Stream<UploadState>.empty(),
      initialState: const UploadState(),
    );
    final router = await pumpRouter(tester);

    router.go('/nope');
    await tester.pumpAndSettle();

    expect(find.text('Page not found'), findsOneWidget);
  });
}
