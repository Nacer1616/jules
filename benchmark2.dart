import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';

Future<void> main() async {
  int width = 640;
  int height = 480;
  int size = width * height;

  Uint32List rgbaList = Uint32List(size);
  // Fill with dummy data
  for (int i=0; i<size; i++) {
    rgbaList[i] = 0xFF000000;
  }

  Stopwatch sw = Stopwatch()..start();
  Completer<ui.Image> completer = Completer();
  ui.decodeImageFromPixels(
    rgbaList.buffer.asUint8List(),
    width,
    height,
    ui.PixelFormat.rgba8888,
    (ui.Image img) {
      completer.complete(img);
    },
  );

  await completer.future;
  sw.stop();
  print('decodeImageFromPixels time: ${sw.elapsedMilliseconds} ms');
}
