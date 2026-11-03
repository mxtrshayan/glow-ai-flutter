import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glow_ai/core/theme.dart';
import 'package:glow_ai/app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glow_ai/features/home/home_screen.dart';

String imageAsset(WidgetTester tester) {
  final image = tester.widget<Image>(find.byType(Image)).image as ResizeImage;
  return (image.imageProvider as AssetImage).assetName;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'HD GIF contains a changing eight-second makeup loop within the size budget',
    () async {
      final file = File('assets/dashboard/makeup-preview-hd.gif');
      final bytes = await file.readAsBytes();
      expect(bytes.length, lessThan(4 * 1024 * 1024));
      final codec = await ui.instantiateImageCodec(bytes);
      expect(codec.frameCount, 80);
      expect(codec.repetitionCount, -1);
      var duration = Duration.zero;
      final samples = <List<int>>[];
      for (var i = 0; i < codec.frameCount; i++) {
        final frame = await codec.getNextFrame();
        duration += frame.duration;
        expect(frame.image.width, 1080);
        expect(frame.image.height, 1350);
        if (i == 0 || i == 50) {
          final pixels = (await frame.image.toByteData())!.buffer.asUint8List();
          final pixel = (805 * 1080 + 540) * 4;
          samples.add(pixels.sublist(pixel, pixel + 3));
        }
        frame.image.dispose();
      }
      codec.dispose();
      expect(duration, const Duration(seconds: 8));
      final difference = List.generate(
        3,
        (i) => (samples[0][i] - samples[1][i]).abs(),
      ).reduce((a, b) => a + b);
      expect(difference, greaterThan(12));
    },
  );

  testWidgets(
    'dashboard prioritises AI and keeps makeup direct with pause/play',
    (tester) async {
      var ai = 0, makeup = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: glowTheme(Brightness.light),
          home: Scaffold(
            body: Home(onConsult: () => ai++, onStudio: () => makeup++),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('AI recommendations')).dy,
        lessThan(tester.getTopLeft(find.text('Virtual makeup')).dy),
      );
      await tester.ensureVisible(find.text('AI recommendations'));
      await tester.tap(find.text('AI recommendations'));
      await tester.ensureVisible(find.text('Virtual makeup'));
      await tester.tap(find.text('Virtual makeup'));
      expect(ai, 1);
      expect(makeup, 1);
      await tester.ensureVisible(find.byTooltip('Pause makeup preview'));
      await tester.tap(find.byTooltip('Pause makeup preview'));
      await tester.pumpAndSettle();
      expect(imageAsset(tester), endsWith('makeup-poster.jpg'));
      await tester.tap(find.byTooltip('Play makeup preview'));
      await tester.pump();
      expect(imageAsset(tester), endsWith('makeup-preview-hd.gif'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reduced motion and inactive dashboard use the still portrait', (
    tester,
  ) async {
    for (final reduced in [true, false]) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: Scaffold(body: MakeupDemo(active: reduced)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(imageAsset(tester), endsWith('makeup-poster.jpg'));
      if (reduced) expect(find.byTooltip('Pause makeup preview'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets(
    'both main actions are visible without scrolling on common phones',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      addTearDown(tester.view.reset);
      for (final size in [const Size(360, 800), const Size(390, 844)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.view.padding = FakeViewPadding(top: 24, bottom: 24);
        tester.view.viewPadding = FakeViewPadding(top: 24, bottom: 24);
        await tester.pumpWidget(const GlowApp());
        await tester.pumpAndSettle();
        final makeupAction = find
            .ancestor(
              of: find.text('Virtual makeup'),
              matching: find.byType(InkWell),
            )
            .first;
        expect(
          tester.getBottomRight(makeupAction).dy,
          lessThanOrEqualTo(tester.getTopLeft(find.byType(NavigationBar)).dy),
          reason: '$size',
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
}
