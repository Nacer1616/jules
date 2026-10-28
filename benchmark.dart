import 'dart:typed_data';

void main() {
  int width = 640;
  int height = 480;
  int size = width * height;

  Uint8List yPlane = Uint8List(size);
  // fill with some data
  for (int i=0; i<size; i++) {
    yPlane[i] = i % 256;
  }

  Uint32List rgbaList = Uint32List(size);
  List<int> palette = List.generate(256, (i) => 0xFF000000 | (i << 16) | (i << 8) | i);

  int iterations = 100;
  Stopwatch sw = Stopwatch()..start();
  for (int j=0; j<iterations; j++) {
    for (int i=0; i<size; i++) {
      rgbaList[i] = palette[yPlane[i]];
    }
  }
  sw.stop();

  print('Average time per frame: ${sw.elapsedMilliseconds / iterations} ms');
}
