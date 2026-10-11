import 'dart:typed_data';

class PickedImage {
  final String base64;     // JPEG, no data: prefix
  final String mediaType;  // 'image/jpeg'
  final Uint8List bytes;   // for showing a preview

  const PickedImage({required this.base64, required this.mediaType, required this.bytes});
}
