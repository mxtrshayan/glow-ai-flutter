import 'support/test_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glow_ai/app.dart';
import 'package:glow_ai/features/studio/studio_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'flow_checks.dart';

void main() {
  late String fixture;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fixture = (await createTemporaryInputImage()).path;
  });
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
    const Size(768, 1024),
    const Size(1024, 768),
    const Size(1366, 1024),
  ]) {
    testWidgets(
      'complete consultation and navigation at ${size.width}x${size.height}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await checkConsultation(tester);
      },
    );
    testWidgets(
      'studio portrait and controls fit ${size.width}x${size.height}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        const channel = MethodChannel('google_mlkit_face_detector');
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(
          channel,
          (call) async => call.method == 'vision#startFaceDetector' ? [] : null,
        );
        addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
        await tester.pumpWidget(
          MaterialApp(
            home: Studio(photo: XFile(fixture), onPhoto: (_) {}),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        expect(find.byType(InteractiveViewer), findsOneWidget);
        expect(find.text('Photos'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('large text remains usable on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const GlowApp());
    await tester.pumpAndSettle();
    await tapLabel(tester, 'AI recommendations');
    await tapLabel(tester, 'Continue without photo');
    expect(tester.takeException(), isNull);
  });
}
