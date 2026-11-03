import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flow_checks.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'consultation validates, preserves input, opens studio and clears session',
    checkConsultation,
  );
  testWidgets('home fits a small phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await checkConsultation(tester);
  });
}
