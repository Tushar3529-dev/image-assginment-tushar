/// Cloudinary settings. Only the cloud name and an UNSIGNED upload preset
/// live in the app — never an API key or secret.
abstract final class AppConfig {
  static const String cloudinaryCloudName = 'fqfo8jif';
  static const String cloudinaryUploadPreset = 'nap_images';

  static Uri get cloudinaryUploadUri => Uri.parse(
    'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload',
  );

  static const String imagesCollection = 'images';
}
