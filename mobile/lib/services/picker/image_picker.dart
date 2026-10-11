// Picks a photo with the device camera (or file picker) and returns it
// downscaled as base64 JPEG. Web uses a plain <input type=file capture>;
// other platforms are not supported yet.
export 'image_picker_stub.dart' if (dart.library.js_interop) 'image_picker_web.dart';
