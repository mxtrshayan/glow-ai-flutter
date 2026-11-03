import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:image_picker/image_picker.dart";
import "package:shared_preferences/shared_preferences.dart";
import "core/theme.dart";
import "core/widgets.dart";
import "features/settings/settings_screen.dart";
import "models/profile.dart";
import "models/recommendation.dart";
import "services/fallback_recommendation_service.dart";
import "features/home/home_screen.dart";
import "features/consultation/consultation_screen.dart";
import "features/results/results_screen.dart";
import "features/studio/studio_screen.dart";
import "features/privacy/privacy_screen.dart";

class GlowApp extends StatefulWidget {
  const GlowApp({super.key});
  @override
  State<GlowApp> createState() => GlowAppState();
}

class GlowAppState extends State<GlowApp> {
  final fallback = const FallbackRecommendationService();
  final navigatorKey = GlobalKey<NavigatorState>();
  Profile profile = Profile();
  Recommendation? result;
  XFile? photo;
  bool darkMode = false;
  bool _themeLoaded = false;
  int _tab = 0;
  int _session = 0;
  bool _studioVisited = false;
  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('glow_session');
    if (mounted) {
      setState(() {
        darkMode = p.getBool('glow_dark_mode') ?? false;
        _themeLoaded = true;
      });
    }
  }

  void _openStudio() {
    navigatorKey.currentState!.push(
      MaterialPageRoute(
        builder: (_) => Studio(
          photo: photo,
          recommendation: result,
          onPhoto: (selected) => setState(() => photo = selected),
        ),
      ),
    );
  }

  Results _results({bool embedded = false}) => Results(
    result: result!,
    onStudio: _openStudio,
    onCreateAnother: () => _openConsultation(replace: !embedded),
  );

  void _openConsultation({bool replace = false}) {
    final route = MaterialPageRoute(
      builder: (_) => Consultation(
        state: this,
        onComplete: () => navigatorKey.currentState!.pushReplacement(
          MaterialPageRoute(builder: (_) => _results()),
        ),
      ),
    );
    if (replace) {
      navigatorKey.currentState!.pushReplacement(route);
    } else {
      navigatorKey.currentState!.push(route);
    }
  }

  Future<void> _setDarkMode(bool value) async {
    setState(() => darkMode = value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('glow_dark_mode', value);
  }

  Future<void> _clearData() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    if (!mounted) return;
    setState(() {
      profile = Profile();
      result = null;
      photo = null;
      darkMode = false;
      _session++;
      _studioVisited = false;
    });
  }

  void _privacy() => navigatorKey.currentState!.push(
    MaterialPageRoute(builder: (_) => const Privacy()),
  );

  Widget _uploadSheet(List<Widget> children) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
  );

  Future<void> _addPhoto(BuildContext context) async {
    final purpose = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _uploadSheet([
        title('Start with your photo.', size: 27),
        const SizedBox(height: 8),
        copy('Choose what you would like to explore.'),
        const SizedBox(height: 20),
        action(
          'Get AI suggestions',
          () => Navigator.pop(context, 2),
          icon: Icons.auto_awesome_outlined,
        ),
        const SizedBox(height: 12),
        action(
          'Try virtual makeup',
          () => Navigator.pop(context, 1),
          secondary: true,
          icon: Icons.face_retouching_natural,
        ),
      ]),
    );
    if (purpose == null || !context.mounted) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _uploadSheet([
        title('Add a portrait', size: 26),
        const SizedBox(height: 8),
        copy('Use a clear photo with one face.'),
        const SizedBox(height: 20),
        photoActions(
          onCamera: () => Navigator.pop(context, ImageSource.camera),
          onGallery: () => Navigator.pop(context, ImageSource.gallery),
        ),
      ]),
    );
    if (source == null) return;
    try {
      final selected = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.front,
      );
      if (!mounted || selected == null) return;
      setState(() => photo = selected);
      if (purpose == 1) {
        setState(() {
          _studioVisited = true;
          _tab = 3;
        });
      } else {
        _openConsultation();
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open your photo. Check permissions and try again.',
            ),
          ),
        );
      }
    }
  }

  Widget _shell(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _tab,
      children: [
        Home(
          active: _tab == 0,
          onConsult: _openConsultation,
          onStudio: () => setState(() {
            _studioVisited = true;
            _tab = 3;
          }),
          onResults: result == null
              ? null
              : () => navigatorKey.currentState!.push(
                  MaterialPageRoute(builder: (_) => _results()),
                ),
        ),
        result != null
            ? _results(embedded: true)
            : SafeArea(
                child: responsiveBody(
                  ListView(
                    padding: const EdgeInsets.all(22),
                    children: [
                      eyebrow('YOUR PERSONAL BEAUTY EDIT'),
                      const SizedBox(height: 8),
                      title('AI recommendations'),
                      const SizedBox(height: 20),
                      card(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: 36,
                              color: accentOf(context),
                            ),
                            const SizedBox(height: 16),
                            title('A look that feels like you.', size: 26),
                            const SizedBox(height: 10),
                            copy(
                              'Create recommendations for your shades, style and occasion. Your current look will appear here.',
                            ),
                            const SizedBox(height: 20),
                            action('Create my look', _openConsultation),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        const SizedBox.shrink(),
        _studioVisited
            ? Studio(
                key: ValueKey(_session),
                photo: photo,
                recommendation: result,
                onPhoto: (selected) => setState(() => photo = selected),
              )
            : const SizedBox.shrink(),
        Settings(
          darkMode: darkMode,
          onDarkMode: _setDarkMode,
          onPrivacy: _privacy,
          onClear: _clearData,
        ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (index) {
        if (index == 2) {
          _addPhoto(context);
          return;
        }
        setState(() {
          _tab = index;
          if (index == 3) _studioVisited = true;
        });
      },
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        const NavigationDestination(
          icon: Icon(Icons.auto_awesome_outlined),
          selectedIcon: Icon(Icons.auto_awesome),
          label: 'AI looks',
        ),
        NavigationDestination(
          icon: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accentOf(context),
              borderRadius: BorderRadius.circular(19),
            ),
            child: Icon(
              Icons.add,
              size: 32,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          label: 'Add photo',
          tooltip: 'Add a photo',
        ),
        const NavigationDestination(
          icon: Icon(Icons.face_retouching_natural_outlined),
          selectedIcon: Icon(Icons.face_retouching_natural),
          label: 'Makeup',
        ),
        const NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: glowTheme(Brightness.light),
    darkTheme: glowTheme(Brightness.dark),
    themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
    builder: (context, child) {
      final dark = isDark(context);
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
          statusBarBrightness: dark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: dark
              ? Brightness.light
              : Brightness.dark,
          systemNavigationBarContrastEnforced: true,
        ),
        child: child!,
      );
    },
    navigatorKey: navigatorKey,
    home: Builder(
      builder: (context) => _themeLoaded
          ? _shell(context)
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    ),
  );
}
