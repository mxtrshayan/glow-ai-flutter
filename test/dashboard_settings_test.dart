import 'support/test_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glow_ai/app.dart';
import 'package:glow_ai/core/color_picker.dart';
import 'package:glow_ai/core/theme.dart';
import 'package:glow_ai/features/settings/settings_screen.dart';
import 'package:glow_ai/features/studio/studio_screen.dart';
import 'flow_checks.dart';

Brightness brightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(NavigationBar))).brightness;

void main() {
  late String fixture;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fixture = (await createTemporaryInputImage()).path;
  });

  testWidgets(
    'light is default, dark mode persists and covers every main flow',
    (tester) async {
      final overlays = <Map<dynamic, dynamic>>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'SystemChrome.setSystemUIOverlayStyle') {
          overlays.add(call.arguments as Map<dynamic, dynamic>);
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await tester.pumpWidget(const GlowApp());
      await tester.pumpAndSettle();
      expect(brightness(tester), Brightness.light);
      await tapLabel(tester, 'Settings');
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(brightness(tester), Brightness.dark);
      expect(
        overlays.last['systemNavigationBarIconBrightness'],
        'Brightness.light',
      );
      expect(
        (await SharedPreferences.getInstance()).getBool('glow_dark_mode'),
        true,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const GlowApp());
      await tester.pumpAndSettle();
      expect(brightness(tester), Brightness.dark);
      await tapLabel(tester, 'Makeup');
      expect(find.byType(Studio), findsOneWidget);
      expect(
        Theme.of(tester.element(find.text('Your portrait'))).brightness,
        Brightness.dark,
      );
      await tapLabel(tester, 'Home');
      await tapLabel(tester, 'AI recommendations');
      await tapLabel(tester, 'Continue without photo');
      final dropdown = find.byKey(const ValueKey('choice-skinTone'));
      expect(Theme.of(tester.element(dropdown)).brightness, Brightness.dark);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tapLabel(tester, 'Settings');
      await tapLabel(tester, 'Privacy policy & about');
      expect(
        Theme.of(tester.element(find.text('Your photos'))).brightness,
        Brightness.dark,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'clear data can be cancelled and removes session and saved theme when confirmed',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'glow_dark_mode': true,
        'glow_session': 'old session',
      });
      await tester.pumpWidget(const GlowApp());
      await tester.pumpAndSettle();
      final state = tester.state<GlowAppState>(find.byType(GlowApp));
      state.profile.event = 'party';
      state.profile.skinTone = 'medium';
      state.result = state.fallback.create(state.profile);
      await tester.pumpAndSettle();
      await tapLabel(tester, 'AI looks');
      await tapLabel(tester, 'Create another look');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      await tapLabel(tester, 'Settings');
      await tapLabel(tester, 'Clear my data');
      await tapLabel(tester, 'Cancel');
      expect(state.result, isNotNull);
      expect(state.darkMode, true);
      await tapLabel(tester, 'Clear my data');
      await tapLabel(tester, 'Clear data');
      expect(state.result, isNull);
      expect(state.photo, isNull);
      expect(state.profile.event, isEmpty);
      expect(brightness(tester), Brightness.light);
      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
      await tapLabel(tester, 'AI looks');
      expect(find.text('A look that feels like you.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'central plus offers both purposes and photo source cancellation is harmless',
    (tester) async {
      await tester.pumpWidget(const GlowApp());
      await tester.pumpAndSettle();
      await tapLabel(tester, 'Add photo');
      expect(find.text('Try virtual makeup'), findsOneWidget);
      expect(find.text('Get AI suggestions'), findsOneWidget);
      await tapLabel(tester, 'Get AI suggestions');
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
      Navigator.of(tester.element(find.text('Add a portrait'))).pop();
      await tester.pumpAndSettle();
      expect(tester.state<GlowAppState>(find.byType(GlowApp)).photo, isNull);
      expect(find.text('Meet your next look.'), findsOneWidget);
    },
  );

  testWidgets(
    'plus photo upload opens the requested consultation with selected portrait',
    (tester) async {
      const picker = MethodChannel('plugins.flutter.io/image_picker');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(picker, (_) async => fixture);
      addTearDown(() => messenger.setMockMethodCallHandler(picker, null));
      await tester.pumpWidget(const GlowApp());
      await tester.pumpAndSettle();
      await tapLabel(tester, 'Add photo');
      await tapLabel(tester, 'Get AI suggestions');
      await tapLabel(tester, 'Photos');
      expect(find.text('Create your look'), findsOneWidget);
      expect(
        tester.state<GlowAppState>(find.byType(GlowApp)).photo?.path,
        fixture,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('dark colour dialog keeps its surface and controls themed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: glowTheme(Brightness.dark),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showMakeupColorPicker(
                context,
                label: 'Test colour',
                initialColor: Colors.red,
              ),
              child: const Text('Colour'),
            ),
          ),
        ),
      ),
    );
    await tapLabel(tester, 'Colour');
    expect(
      Theme.of(tester.element(find.byType(Dialog))).brightness,
      Brightness.dark,
    );
    expect(
      tester.widget<Dialog>(find.byType(Dialog)).backgroundColor,
      const Color(0xFF1B151A),
    );
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 568),
    const Size(844, 390),
    const Size(768, 1024),
  ]) {
    testWidgets(
      'settings and plus fit dark mode at $size with system navigation inset',
      (tester) async {
        SharedPreferences.setMockInitialValues({'glow_dark_mode': true});
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.view.padding = FakeViewPadding(bottom: 48);
        tester.view.viewPadding = FakeViewPadding(bottom: 48);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(const GlowApp());
        await tester.pumpAndSettle();
        await tapLabel(tester, 'Settings');
        expect(find.byType(Settings), findsOneWidget);
        expect(
          tester.getBottomRight(find.byType(NavigationBar)).dy,
          size.height,
        );
        await tapLabel(tester, 'Clear my data');
        await tapLabel(tester, 'Cancel');
        await tapLabel(tester, 'Add photo');
        expect(
          tester.getBottomRight(find.text('Get AI suggestions')).dy,
          lessThanOrEqualTo(size.height - 48),
        );
        await tapLabel(tester, 'Try virtual makeup');
        expect(find.text('Photos'), findsOneWidget);
        expect(
          tester.getBottomRight(find.text('Photos')).dy,
          lessThanOrEqualTo(size.height - 48),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
