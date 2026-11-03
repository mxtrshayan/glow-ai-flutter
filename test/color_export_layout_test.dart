import 'support/test_image.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glow_ai/core/color_picker.dart';
import 'package:glow_ai/core/widgets.dart';
import 'package:glow_ai/services/makeup_export_service.dart';
import 'flow_checks.dart';
import 'makeup_painter_test.dart' as makeup;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late String fixture;
  setUp(() async => fixture = (await createTemporaryInputImage()).path);
  testWidgets(
    'full colour picker accepts any RGB shade and cancels without applying',
    (tester) async {
      Color? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => action('Pick colour', () async {
                selected = await showMakeupColorPicker(
                  context,
                  label: 'Lipstick colour',
                  initialColor: Colors.red,
                );
              }),
            ),
          ),
        ),
      );
      await tapLabel(tester, 'Pick colour');
      await tester.enterText(
        find.byKey(const ValueKey('colour-hex')),
        '12ABEF',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tapLabel(tester, 'Apply colour');
      expect(selected, const Color(0xFF12ABEF));
      await tapLabel(tester, 'Pick colour');
      await tapLabel(tester, 'Cancel');
      expect(selected, isNull);
    },
  );
  testWidgets(
    'photo buttons share a height and bottom controls avoid system buttons',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = FakeViewPadding(bottom: 48);
      tester.view.viewPadding = FakeViewPadding(bottom: 48);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: responsiveBody(
              Column(
                children: [
                  photoActions(onCamera: () {}, onGallery: () {}),
                  const Expanded(child: SizedBox()),
                  action('Bottom action', () {}),
                ],
              ),
            ),
          ),
        ),
      );
      final buttons = find.byType(OutlinedButton);
      expect(
        tester.getSize(buttons.at(0)).height,
        tester.getSize(buttons.at(1)).height,
      );
      expect(
        tester.getSize(buttons.at(0)).height,
        tester.getSize(buttons.at(2)).height,
      );
      expect(tester.getBottomRight(buttons.at(2)).dy, lessThanOrEqualTo(592));
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'download composites a full-sized PNG and cleans up its temporary file',
    () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      String? temporaryPath;
      messenger.setMockMethodCallHandler(MakeupExportService.channel, (
        call,
      ) async {
        expect(call.method, 'saveImage');
        temporaryPath = call.arguments['path'] as String;
        final bytes = await File(temporaryPath!).readAsBytes();
        expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
        final codec = await ui.instantiateImageCodec(bytes);
        final image = (await codec.getNextFrame()).image;
        expect(image.width, 512);
        expect(image.height, 512);
        image.dispose();
        codec.dispose();
        return true;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          MakeupExportService.channel,
          null,
        ),
      );
      expect(
        await MakeupExportService().save(fixture, makeup.painter(lips: true)),
        isTrue,
      );
      expect(await File(temporaryPath!).exists(), isFalse);
    },
  );
  test(
    'canceling the native save dialog returns without saving or leaving files',
    () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      String? path;
      messenger.setMockMethodCallHandler(MakeupExportService.channel, (
        call,
      ) async {
        path = call.arguments['path'];
        return false;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          MakeupExportService.channel,
          null,
        ),
      );
      expect(
        await MakeupExportService().save(fixture, makeup.painter()),
        isFalse,
      );
      expect(await File(path!).exists(), isFalse);
    },
  );
}
