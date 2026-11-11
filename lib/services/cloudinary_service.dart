import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/app_config.dart';

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

  Future<({String url, String publicId})> uploadImage(File file) async {
    final request = http.MultipartRequest('POST', AppConfig.cloudinaryUploadUri)
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
