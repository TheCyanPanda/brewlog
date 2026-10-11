import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:math' as math;

import 'package:web/web.dart' as web;

import 'picked_image.dart';

export 'picked_image.dart';

// Longest side after downscaling: plenty for reading a label, small upload
const int _kMaxSide = 1280;

Future<PickedImage?> pickImage({bool camera = true}) async {
  final web.HTMLInputElement input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/*';
  // On phones this opens the rear camera directly; desktops show a file dialog
  if (camera) input.setAttribute('capture', 'environment');

  final Completer<web.File?> picked = Completer<web.File?>();
  input.onchange = ((web.Event _) {
    if (!picked.isCompleted) picked.complete(input.files?.item(0));
  }).toJS;
  input.addEventListener('cancel', ((web.Event _) {
    if (!picked.isCompleted) picked.complete(null);
  }).toJS);
  input.click();

  final web.File? file = await picked.future;
  if (file == null) return null;

  // Decode, downscale on a canvas and re-encode as JPEG
  final web.ImageBitmap bitmap = await web.window.createImageBitmap(file).toDart;
  final double scale = math.min(1.0, _kMaxSide / math.max(bitmap.width, bitmap.height));
  final int w = (bitmap.width * scale).round();
  final int h = (bitmap.height * scale).round();

  final web.HTMLCanvasElement canvas = web.HTMLCanvasElement()
    ..width = w
    ..height = h;
  final web.CanvasRenderingContext2D ctx = canvas.getContext('2d')! as web.CanvasRenderingContext2D;
  ctx.drawImage(bitmap, 0, 0, w, h);
  bitmap.close();

  final String dataUrl = canvas.toDataURL('image/jpeg', 0.85.toJS);
  final String b64 = dataUrl.substring(dataUrl.indexOf(',') + 1);
  return PickedImage(base64: b64, mediaType: 'image/jpeg', bytes: base64Decode(b64));
}
