import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_assignment/services/cloudinary_service.dart';

void main() {
  late File image;

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('cloudinary_test');
    image = File('${dir.path}/photo.jpg')
      ..writeAsBytesSync(List<int>.filled(200 * 1024, 7));
    addTearDown(() => dir.delete(recursive: true));
  });

  test('reports byte progress up to 1.0 and returns url + public id', () async {
    late http.BaseRequest seen;
    final service = CloudinaryService(
      client: MockClient((request) async {
        seen = request;
        return http.Response(
          jsonEncode({'secure_url': 'https://res/x.jpg', 'public_id': 'x'}),
          200,
        );
      }),
    );
    final progress = <double>[];

    final result = await service.uploadImage(image, onProgress: progress.add);

    expect(result.url, 'https://res/x.jpg');
    expect(result.publicId, 'x');
    final body = utf8.decode(
      (seen as http.Request).bodyBytes,
      allowMalformed: true,
    );
    expect(body, contains('name="upload_preset"'));
    expect(body, contains('nap_images'));
    expect(progress, isNotEmpty);
    expect(progress.last, 1.0);
    for (var i = 1; i < progress.length; i++) {
      expect(progress[i], greaterThanOrEqualTo(progress[i - 1]));
    }
  });

  test('a non-200 response throws a readable CloudinaryException', () async {
    final service = CloudinaryService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {'message': 'Upload preset not found'},
          }),
          400,
        ),
      ),
    );

    expect(
      () => service.uploadImage(image),
      throwsA(
        isA<CloudinaryException>().having(
          (e) => e.message,
          'message',
          'Upload failed (400): Upload preset not found',
        ),
      ),
    );
  });
}
