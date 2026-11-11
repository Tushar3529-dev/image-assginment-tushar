import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/app_config.dart';

/// Called with the fraction of the request body sent so far (0.0 to 1.0).
typedef UploadProgress = void Function(double fraction);

class CloudinaryException implements Exception {
  const CloudinaryException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Uploads images to Cloudinary through an UNSIGNED preset.
class CloudinaryService {
  CloudinaryService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<({String url, String publicId})> uploadImage(
    File file, {
    UploadProgress? onProgress,
  }) async {
    final request =
        _ProgressMultipartRequest(
            'POST',
            AppConfig.cloudinaryUploadUri,
            onProgress: onProgress,
          )
          ..fields['upload_preset'] = AppConfig.cloudinaryUploadPreset
          ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final http.Response response;
    try {
      response = await http.Response.fromStream(await _client.send(request));
    } on SocketException {
      throw const CloudinaryException(
        'No internet connection. Please try again.',
      );
    } on http.ClientException catch (e) {
      throw CloudinaryException('Upload failed: ${e.message}');
    }

    Map<String, dynamic>? body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      body = null;
    }

    if (response.statusCode != 200) {
      final apiMessage = (body?['error'] as Map<String, dynamic>?)?['message'];
      throw CloudinaryException(
        'Upload failed (${response.statusCode})'
        '${apiMessage is String ? ': $apiMessage' : ''}',
      );
    }

    final url = body?['secure_url'];
    final publicId = body?['public_id'];
    if (url is! String || publicId is! String) {
      throw const CloudinaryException(
        'Upload failed: unexpected response from Cloudinary.',
      );
    }
    return (url: url, publicId: publicId);
  }
}

/// A multipart request that reports how much of its body has been handed to
/// the client. That's the real upload progress, measured in bytes.
class _ProgressMultipartRequest extends http.MultipartRequest {
  _ProgressMultipartRequest(super.method, super.url, {this.onProgress});

  final UploadProgress? onProgress;

  @override
  http.ByteStream finalize() {
    final callback = onProgress;
    final total = contentLength;
    final stream = super.finalize();
    if (callback == null || total <= 0) return stream;

    var sent = 0;
    return http.ByteStream(
      stream.transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (chunk, sink) {
            sent += chunk.length;
            callback((sent / total).clamp(0.0, 1.0));
            sink.add(chunk);
          },
        ),
      ),
    );
  }
}
