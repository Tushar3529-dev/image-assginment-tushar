import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_assignment/blocs/images/images_bloc.dart';
import 'package:image_assignment/models/image_item.dart';
import 'package:image_assignment/screens/images/images_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockImagesBloc extends MockBloc<ImagesEvent, ImagesState>
    implements ImagesBloc {}

final photo = ImageItem(
  id: 'p1',
  referenceName: 'Beach',
  imageUrl: 'https://example.invalid/p1.jpg',
  publicId: 'p1',
  createdAt: DateTime(2026),
);

void main() {
  late MockImagesBloc bloc;

  setUpAll(() => registerFallbackValue(const ImagesSubscriptionRequested()));

  setUp(() {
    bloc = MockImagesBloc();
    whenListen(
      bloc,
      const Stream<ImagesState>.empty(),
      initialState: ImagesState(status: ImagesStatus.loaded, images: [photo]),
    );
  });

  Future<void> openMenuAndChooseDelete(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1206, 2622); // iPhone 17 Pro
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ImagesBloc>.value(
          value: bloc,
          child: const ImagesScreen(),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Photo options'));
    // Let the menu finish its open animation before tapping an item.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Delete photo'), findsOneWidget);

    await tester.tap(find.text('Delete photo'));
    // The menu closes first, then the confirm dialog opens.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.text('Delete photo?'), findsOneWidget);
    expect(find.textContaining("'Beach'"), findsOneWidget);
  }

  testWidgets('⋮ → Delete photo → Delete sends ImageDeleteRequested', (
    tester,
  ) async {
    await openMenuAndChooseDelete(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pump(const Duration(milliseconds: 600));

    verify(() => bloc.add(ImageDeleteRequested(photo))).called(1);
  });

  testWidgets('Cancel in the confirm dialog deletes nothing', (tester) async {
    await openMenuAndChooseDelete(tester);

    await tester.tap(find.text('Cancel'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('Delete photo?'), findsNothing);
    verifyNever(() => bloc.add(any(that: isA<ImageDeleteRequested>())));
  });
}
