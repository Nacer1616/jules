# Thermal Camera Application

This project is a mobile application developed with Flutter that simulates a thermal camera effect in real-time. It uses the phone's back camera and maps luminance or RGB contrast levels to classic thermal color palettes.

## Key Features
1. **Camera Preview**: Accesses the device's back camera and displays the live feed efficiently.
2. **Real-Time Color Mapping (Thermal Palette Filter)**:
   - Evaluates luminance directly from YUV420 format (Android) or calculates it from BGRA8888 (iOS).
   - Maps the luminance values to thermal color palettes (Ironbow, Rainbow, White Hot, Black Hot).
3. **UI Controls**:
   - A palette button to cycle between different thermal color palettes.
   - A snapshot button to save the current filtered view to the phone's gallery.
   - A torch/flashlight toggle button in the AppBar for low light assistance.
4. **Performance**: Optimized mapping utilizing single-array lookups ensuring minimal latency and smooth frame processing.

## Project Structure
- `lib/main.dart`: Contains the main UI, camera initialization, image stream processing logic, torch toggle, snapshot functionality, and custom drawing.
- `lib/thermal_palettes.dart`: Provides the definitions for various thermal gradient stops and a generator for 256-color lookup tables.
- `android/app/src/main/AndroidManifest.xml`: Configured for Camera, Flashlight, and Storage permissions for Android.
- `ios/Runner/Info.plist`: Configured with Camera and Photo Library usage descriptions for iOS.

## Prerequisites
- Flutter SDK (stable channel)
- Android Studio or Xcode for native compilation

## How to Build and Run
1. Switch into the app directory:
   ```bash
   cd thermal_camera_app
   ```
2. Get dependencies:
   ```bash
   flutter pub get
   ```
3. Connect a physical device (Camera and Torch will not function completely on a standard emulator).
4. Run the app:
   ```bash
   flutter run
   ```
5. To build an APK for Android:
   ```bash
   flutter build apk
   ```

## Dependencies
- `camera`: For accessing the device's cameras and streaming frames.
- `torch_light`: For toggling the device flashlight.
- `gallery_saver_plus`: For saving screenshots directly to the device gallery.
- `path_provider`: For accessing temporary directories to stage screenshots.
- `image`: For image conversions.
- `permission_handler`: For handling dynamic runtime permissions on Android/iOS (currently pre-configured via native manifests as well).
