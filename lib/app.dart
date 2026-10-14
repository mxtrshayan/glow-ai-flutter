import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:image_picker/image_picker.dart";
import "package:shared_preferences/shared_preferences.dart";
import "core/theme.dart";
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
  @override
  void initState() {
    super.initState();
    _clearCache();
  }

  Future<void> _clearCache() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('glow_session');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          foregroundColor: ink,
          elevation: 0,
        ),
      ),
      navigatorKey: navigatorKey,
      home: Home(
        onConsult: () => navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => Consultation(
              state: this,
              onComplete: () => navigatorKey.currentState!.pushReplacement(
                MaterialPageRoute(
                  builder: (_) => Results(
                    result: result!,
                    onStudio: () => navigatorKey.currentState!.push(
                      MaterialPageRoute(
                        builder: (_) => Studio(
                          photo: photo,
                          onPhoto: (p) => setState(() => photo = p),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        onStudio: () => navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) =>
                Studio(photo: photo, onPhoto: (p) => setState(() => photo = p)),
          ),
        ),
        onPrivacy: () => navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => Privacy(
              onClear: () => setState(() {
                profile = Profile();
                result = null;
                photo = null;
              }),
            ),
          ),
        ),
        onResults: result == null
            ? null
            : () => navigatorKey.currentState!.push(
                MaterialPageRoute(
                  builder: (_) => Results(
                    result: result!,
                    onStudio: () => navigatorKey.currentState!.push(
                      MaterialPageRoute(
                        builder: (_) => Studio(
                          photo: photo,
                          onPhoto: (p) => setState(() => photo = p),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
