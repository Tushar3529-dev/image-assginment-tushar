import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_config.dart';
import '../models/image_item.dart';

class ImageRepository {
  ImageRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _images =>
      _firestore.collection(AppConfig.imagesCollection);

  /// Live stream of every image, oldest first. Each add/delete in Firestore
  /// (from this app or the console) pushes a new list.
  Stream<List<ImageItem>> watchImages() => _images
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map(ImageItem.fromDoc).toList());

  Future<void> addImage({
    required String referenceName,
    required String imageUrl,
    required String publicId,
  }) {
    return _images.add({
      'referenceName': referenceName,
      'imageUrl': imageUrl,
      'publicId': publicId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes the Firestore document. The live stream then drops the tile on
  /// every device. The Cloudinary file is NOT removed: that needs the API
  /// secret, which must never ship in the app (see README).
  Future<void> deleteImage(String id) => _images.doc(id).delete();
}
