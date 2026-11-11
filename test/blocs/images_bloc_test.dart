import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_assignment/blocs/images/images_bloc.dart';
import 'package:image_assignment/models/image_item.dart';
import 'package:image_assignment/repositories/image_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockImageRepository extends Mock implements ImageRepository {}

void main() {
  late MockImageRepository repository;

  final a = ImageItem(
    id: 'a',
    referenceName: 'A',
    imageUrl: 'https://x/a.jpg',
    publicId: 'nap_images/a',
    createdAt: DateTime(2026),
  );
  final b = ImageItem(
    id: 'b',
    referenceName: 'B',
    imageUrl: 'https://x/b.jpg',
    publicId: 'nap_images/b',
    createdAt: DateTime(2026, 2),
  );

  setUp(() => repository = MockImageRepository());

  blocTest<ImagesBloc, ImagesState>(
    'stream emitting two lists produces two loaded states',
    setUp: () => when(() => repository.watchImages()).thenAnswer(
      (_) => Stream.fromIterable([
        [a],
        [a, b],
      ]),
    ),
    build: () => ImagesBloc(repository),
    act: (bloc) => bloc.add(const ImagesSubscriptionRequested()),
    expect: () => [
      ImagesState(status: ImagesStatus.loaded, images: [a]),
      ImagesState(status: ImagesStatus.loaded, images: [a, b]),
    ],
  );

  blocTest<ImagesBloc, ImagesState>(
    'stream error produces failure',
    setUp: () => when(
      () => repository.watchImages(),
    ).thenAnswer((_) => Stream.error(Exception('boom'))),
    build: () => ImagesBloc(repository),
    act: (bloc) => bloc.add(const ImagesSubscriptionRequested()),
    expect: () => [
      isA<ImagesState>().having(
        (s) => s.status,
        'status',
        ImagesStatus.failure,
      ),
    ],
  );
}
