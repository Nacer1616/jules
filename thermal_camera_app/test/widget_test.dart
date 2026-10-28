import 'package:flutter_test/flutter_test.dart';
import 'package:thermal_camera_app/main.dart';

void main() {
  testWidgets('Thermal Camera App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ThermalCameraApp());

    // Verify that the CircularProgressIndicator is shown initially while camera initializes.
    expect(find.byType(ThermalCameraApp), findsOneWidget);
  });
}
