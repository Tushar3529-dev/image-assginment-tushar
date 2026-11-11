import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_assignment/blocs/images/images_bloc.dart';
import 'package:image_assignment/core/app_scroll_behavior.dart';
import 'package:image_assignment/models/image_item.dart';
import 'package:image_assignment/screens/images/images_screen.dart';

class MockImagesBloc extends MockBloc<ImagesEvent, ImagesState>
    implements ImagesBloc {}

ImageItem item(int i) => ImageItem(
  id: 'id$i',
  referenceName: 'Photo $i',
  imageUrl: 'https://example.invalid/$i.jpg',
  publicId: 'p$i',
  createdAt: DateTime(2026, 1, i + 1),
);

void main() {
  Future<void> pumpGrid(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final bloc = MockImagesBloc();
    whenListen(
      bloc,
      const Stream<ImagesState>.empty(),
      initialState: ImagesState(
        status: ImagesStatus.loaded,
        images: [for (var i = 0; i < 12; i++) item(i)],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: const AppScrollBehavior(),
        home: BlocProvider<ImagesBloc>.value(
          value: bloc,
          child: const ImagesScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  double offset(WidgetTester tester) => tester
      .state<ScrollableState>(find.byType(Scrollable).first)
      .position
      .pixels;

  for (final kind in [
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  ]) {
    testWidgets('the Images grid scrolls with a ${kind.name} drag', (
      tester,
    ) async {
      await pumpGrid(tester);
      expect(offset(tester), 0);

      await tester.dragFrom(
        const Offset(200, 600),
        const Offset(0, -400),
        kind: kind,
      );
      await tester.pump(const Duration(seconds: 1));

      expect(offset(tester), greaterThan(100), reason: '${kind.name} drag');
    });
  }

  testWidgets('the Images grid scrolls with a mouse wheel', (tester) async {
    await pumpGrid(tester);
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(const Offset(200, 400)));
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 300)));
    await tester.pump(const Duration(seconds: 1));

    expect(offset(tester), greaterThan(100));
  });
}
