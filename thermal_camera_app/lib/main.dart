import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'thermal_palettes.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Error: $e.code\nError Message: $e.message');
  }
  runApp(const ThermalCameraApp());
}

class ThermalCameraApp extends StatelessWidget {
  const ThermalCameraApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thermal Camera',
      theme: ThemeData.dark(),
      home: const ThermalCameraScreen(),
    );
  }
}

class ThermalCameraScreen extends StatefulWidget {
  const ThermalCameraScreen({Key? key}) : super(key: key);

  @override
  _ThermalCameraScreenState createState() => _ThermalCameraScreenState();
}

class _ThermalCameraScreenState extends State<ThermalCameraScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  ui.Image? _currentFrame;
  bool _isTorchOn = false;

  // Palettes
  final Map<String, List<int>> _palettes = {
    'Ironbow': ThermalPalettes.generatePalette(ThermalPalettes.ironbow),
    'Rainbow': ThermalPalettes.generatePalette(ThermalPalettes.rainbow),
    'White Hot': ThermalPalettes.generatePalette(ThermalPalettes.whiteHot),
    'Black Hot': ThermalPalettes.generatePalette(ThermalPalettes.blackHot),
  };
  String _currentPaletteName = 'Ironbow';
  late List<int> _currentPalette;

  @override
  void initState() {
    super.initState();
    _currentPalette = _palettes[_currentPaletteName]!;
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) return;

    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      backCamera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
    );

    try {
      await _controller!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
      _controller!.startImageStream((CameraImage image) {
        if (!_isProcessing) {
          _processCameraImage(image);
        }
      });
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    _isProcessing = true;
    try {
      final int width = image.width;
      final int height = image.height;
      Uint32List rgbaList = Uint32List(width * height);

      if (image.format.group == ImageFormatGroup.yuv420) {
        final Uint8List yPlane = image.planes[0].bytes;
        final int yRowStride = image.planes[0].bytesPerRow;

        // Process taking row stride into account
        for (int y = 0; y < height; y++) {
          for (int x = 0; x < width; x++) {
            int yIndex = y * yRowStride + x;
            int luma = yPlane[yIndex];
            rgbaList[y * width + x] = _currentPalette[luma];
          }
        }
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        final Uint8List bytes = image.planes[0].bytes;
        final int bytesPerRow = image.planes[0].bytesPerRow;

        for (int y = 0; y < height; y++) {
          for (int x = 0; x < width; x++) {
            int pixelOffset = y * bytesPerRow + x * 4;
            int b = bytes[pixelOffset];
            int g = bytes[pixelOffset + 1];
            int r = bytes[pixelOffset + 2];
            int luma = (0.299 * r + 0.587 * g + 0.114 * b).round().clamp(0, 255);
            rgbaList[y * width + x] = _currentPalette[luma];
          }
        }
      }

      final Completer<ui.Image> completer = Completer();
      ui.decodeImageFromPixels(
        rgbaList.buffer.asUint8List(),
        width,
        height,
        ui.PixelFormat.bgra8888,
        (ui.Image img) {
          completer.complete(img);
        },
      );

      final ui.Image renderedImage = await completer.future;
      if (mounted) {
        // Dispose of the previous frame to avoid memory leaks
        _currentFrame?.dispose();

        setState(() {
          _currentFrame = renderedImage;
        });
      } else {
        renderedImage.dispose();
      }
    } catch (e) {
      debugPrint("Error processing frame: $e");
    } finally {
      _isProcessing = false;
    }
  }

  void _cyclePalette() {
    final keys = _palettes.keys.toList();
    final currentIndex = keys.indexOf(_currentPaletteName);
    final nextIndex = (currentIndex + 1) % keys.length;
    setState(() {
      _currentPaletteName = keys[nextIndex];
      _currentPalette = _palettes[_currentPaletteName]!;
    });
  }

  Future<void> _toggleTorch() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      if (_isTorchOn) {
        await _controller!.setFlashMode(FlashMode.off);
      } else {
        await _controller!.setFlashMode(FlashMode.torch);
      }
      setState(() {
        _isTorchOn = !_isTorchOn;
      });
    } catch (e) {
      debugPrint("Error toggling torch: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle flashlight: $e')),
        );
      }
    }
  }

  Future<void> _takeSnapshot() async {
    if (_currentFrame == null) return;

    try {
      final ui.Image image = _currentFrame!;
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/thermal_snapshot_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(pngBytes);

      await GallerySaver.saveImage(path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Snapshot saved to gallery!')),
        );
      }
    } catch (e) {
      debugPrint("Error saving snapshot: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save snapshot: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    _currentFrame?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thermal Camera'),
        actions: [
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleTorch,
            tooltip: 'Toggle Flashlight',
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_currentFrame != null)
            CustomPaint(
              painter: ThermalImagePainter(_currentFrame!),
              size: Size.infinite,
            ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: 'palette_btn',
                  onPressed: _cyclePalette,
                  child: const Icon(Icons.palette),
                  tooltip: 'Change Palette',
                ),
                FloatingActionButton(
                  heroTag: 'snapshot_btn',
                  onPressed: _takeSnapshot,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.camera_alt, color: Colors.white),
                  tooltip: 'Take Snapshot',
                ),
              ],
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                _currentPaletteName,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ThermalImagePainter extends CustomPainter {
  final ui.Image image;

  ThermalImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Calculate aspect ratios
    double imageAspectRatio = image.height / image.width;
    double canvasAspectRatio = size.height / size.width;

    Rect src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    Rect dst;

    // Scale and center image on canvas while maintaining aspect ratio
    if (imageAspectRatio > canvasAspectRatio) {
      // Image is taller than canvas
      double drawWidth = size.height / imageAspectRatio;
      double xOffset = (size.width - drawWidth) / 2;
      dst = Rect.fromLTWH(xOffset, 0, drawWidth, size.height);
    } else {
      // Image is wider than canvas
      double drawHeight = size.width * imageAspectRatio;
      double yOffset = (size.height - drawHeight) / 2;
      dst = Rect.fromLTWH(0, yOffset, size.width, drawHeight);
    }

    // Android camera feed often needs 90 degree rotation
    // This depends on the device orientation. For simplicity, we just draw the image.
    // In a production app, we would handle camera sensor orientation properly.

    canvas.save();

    // Note: Android back camera images are usually rotated 90 degrees clockwise
    if (Platform.isAndroid) {
      canvas.translate(size.width / 2, size.height / 2);
      canvas.rotate(90 * 3.1415927 / 180);

      // Recalculate dst for rotated canvas
      if (1/imageAspectRatio > canvasAspectRatio) {
        double drawWidth = size.height * imageAspectRatio;
        double xOffset = -drawWidth / 2;
        dst = Rect.fromLTWH(xOffset, -size.width/2, drawWidth, size.width);
      } else {
        double drawHeight = size.width / imageAspectRatio;
        double yOffset = -drawHeight / 2;
        dst = Rect.fromLTWH(-size.height/2, yOffset, size.height, drawHeight);
      }
    }

    canvas.drawImageRect(image, src, dst, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ThermalImagePainter oldDelegate) {
    return oldDelegate.image != image;
  }
}
