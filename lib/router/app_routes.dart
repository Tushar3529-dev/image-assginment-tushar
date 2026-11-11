/// Route paths and names. Widgets use these constants, never raw strings.
abstract final class AppRoutes {
  static const String upload = '/upload';
  static const String uploadPreviewSegment = 'preview';
  static const String uploadPreview = '$upload/$uploadPreviewSegment';
  static const String images = '/images';

  static const String uploadName = 'upload';
  static const String uploadPreviewName = 'uploadPreview';
  static const String imagesName = 'images';
}
