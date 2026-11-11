import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_assignment/blocs/images/images_bloc.dart';
import 'package:image_assignment/models/image_item.dart';
import 'package:image_assignment/screens/images/images_screen.dart';

class MockImagesBloc extends MockBloc<ImagesEvent, ImagesState>
    implements ImagesBloc {}

ImageItem item(String id) => ImageItem(
  id: id,
  referenceName: 'Photo $id',
  imageUrl: 'https://example.invalid/$id.jpg',
  publicId: id,
  createdAt: DateTime(2026),
);

void main() {
  testWidgets('a new doc pops in with a New badge; a deleted one fades out', (
    tester,
  ) async {
    final bloc = MockImagesBloc();
    final states = StreamController<ImagesState>();
    addTearDown(states.close);
    whenListen(
      bloc,
      states.stream,
      initialState: ImagesState(
        status: ImagesStatus.loaded,
        images: [item('a')],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ImagesBloc>.value(
          value: bloc,
          child: const ImagesScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Photo a'), findsOneWidget);
    // Items present on first load are not marked new.
    expect(find.byType(ImageTile), findsOneWidget);
    expect(tester.widget<ImageTile>(find.byType(ImageTile)).fresh, isFalse);

    // A document arrives live.
    states.add(
      ImagesState(status: ImagesStatus.loaded, images: [item('a'), item('b')]),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Photo b'), findsOneWidget);
    final fresh = tester
        .widgetList<ImageTile>(find.byType(ImageTile))
        .firstWhere((t) => t.item.id == 'b');
    expect(fresh.fresh, isTrue);
    expect(find.text('2'), findsOneWidget); // header count

    // The highlight wears off.
    await tester.pump(const Duration(seconds: 3));
    expect(
      tester
          .widgetList<ImageTile>(find.byType(ImageTile))
          .every((t) => !t.fresh),
      isTrue,
    );

    // 'a' is deleted in the console: it animates out, then is gone.
    states.add(ImagesState(status: ImagesStatus.loaded, images: [item('b')]));
    await tester.pump();
    expect(find.text('Photo a'), findsOneWidget); // still fading out
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Photo a'), findsNothing);
    expect(find.text('Photo b'), findsOneWidget);

    // Everything deleted: empty state.
    states.add(const ImagesState(status: ImagesStatus.loaded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('No images yet'), findsOneWidget);
  });
}
