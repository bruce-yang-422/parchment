import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import '../core/l10n/tr.dart';

/// Saves images through the system "save as" dialog (Android SAF / iOS
/// document picker), so no storage permission is required.
class ImageExporter {
  const ImageExporter._();

  /// Returns `true` when saved, `false` when the user cancelled.
  static Future<bool> savePng(
    Uint8List bytes, {
    required String fileName,
  }) async {
    final uri = await FilePicker.saveFile(
      dialogTitle: tr('儲存圖片'),
      fileName: fileName,
      bytes: bytes,
      mimeType: 'image/png',
    );
    return uri != null;
  }

  /// Draws a transparent PNG onto an opaque [background] with [padding]
  /// (in source pixels) so the exported image stays legible in any viewer.
  static Future<Uint8List> flattenPng(
    Uint8List png, {
    required ui.Color background,
    double padding = 48,
  }) async {
    final codec = await ui.instantiateImageCodec(png);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final width = image.width + padding * 2;
    final height = image.height + padding * 2;
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder)
      ..drawRect(
        ui.Rect.fromLTWH(0, 0, width, height),
        ui.Paint()..color = background,
      )
      ..drawImage(image, ui.Offset(padding, padding), ui.Paint());
    final output = await recorder.endRecording().toImage(
      width.round(),
      height.round(),
    );
    final data = await output.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    output.dispose();
    codec.dispose();
    return data!.buffer.asUint8List();
  }
}
