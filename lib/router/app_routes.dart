/// Route paths and names. Widgets use these constants, never raw strings.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String upload = '/upload';
  static const String uploadPreviewSegment = 'preview';
  static const String uploadPreview = '$upload/$uploadPreviewSegment';
  static const String images = '/images';
  static const String imageViewerSegment = 'view/:id';

  /// Full-screen viewer for one image, e.g. `/images/view/abc123`.
  static String imageViewer(String id) => '$images/view/$id';

  static const String splashName = 'splash';
  static const String uploadName = 'upload';
  static const String uploadPreviewName = 'uploadPreview';
  static const String imagesName = 'images';
  static const String imageViewerName = 'imageViewer';
}
