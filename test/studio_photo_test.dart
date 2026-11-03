import 'support/test_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glow_ai/features/studio/studio_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late String fixture;
  setUp(() async => fixture = (await createTemporaryInputImage()).path);
  const picker = MethodChannel('plugins.flutter.io/image_picker');
  const detector = MethodChannel('google_mlkit_face_detector');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() {
    messenger.setMockMethodCallHandler(picker, null);
    messenger.setMockMethodCallHandler(detector, null);
  });
  testWidgets('gallery selection updates the studio without a parent rebuild', (
    tester,
  ) async {
    String? selected;
    messenger.setMockMethodCallHandler(picker, (_) async => fixture);
    messenger.setMockMethodCallHandler(
      detector,
      (call) async => call.method == 'vision#startFaceDetector' ? [] : null,
    );
    await tester.pumpWidget(
      MaterialApp(home: Studio(photo: null, onPhoto: (p) => selected = p.path)),
    );
    await tester.ensureVisible(find.text('Photos'));
    await tester.runAsync(() async {
      await tester.tap(find.text('Photos'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(selected, fixture);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Your portrait'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('camera errors are shown without crashing', (tester) async {
    messenger.setMockMethodCallHandler(
      picker,
      (_) async => throw PlatformException(code: 'camera_access_denied'),
    );
    await tester.pumpWidget(
      MaterialApp(home: Studio(photo: null, onPhoto: (_) {})),
    );
    await tester.ensureVisible(find.text('Camera'));
    await tester.tap(find.text('Camera'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Check permissions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
