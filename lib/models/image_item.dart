import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ImageItem extends Equatable {
  const ImageItem({
    required this.id,
    required this.referenceName,
    required this.imageUrl,
    required this.publicId,
    required this.createdAt,
  });

  final String id;
  final String referenceName;
  final String imageUrl;
  final String publicId;
  final DateTime createdAt;

  /// A doc that was just written locally has `createdAt == null` until the
  /// server fills in the timestamp. FlutterFire's `snapshots()` has no
  /// `ServerTimestampBehavior.estimate` option (only `GetOptions` for a
  /// one-off `.get()` does), so we fall back to the local clock — the same
  /// thing "estimate" does — and never throw on null.
  factory ImageItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final ts = data['createdAt'];
    return ImageItem(
      id: doc.id,
      referenceName: (data['referenceName'] as String?) ?? '',
      imageUrl: (data['imageUrl'] as String?) ?? '',
      publicId: (data['publicId'] as String?) ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, referenceName, imageUrl, publicId, createdAt];
}
