import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'models/recommendation.dart';
import 'services/gemini_key_pool.dart';

class AiService {
  final http.Client? client;
  final GeminiKeyPool? keyPool;
  final Duration attemptTimeout;
  final Duration overallTimeout;
  const AiService({
    this.client,
    this.keyPool,
    this.attemptTimeout = const Duration(seconds: 8),
    this.overallTimeout = const Duration(seconds: 20),
  });
  static GeminiKeyPool? _sharedPool;

  static List<String> get configuredKeys => {
    ...config('GEMINI_API_KEYS').split(RegExp(r'[,;\s]+')),
    config('GEMINI_API_KEY'),
    for (var index = 1; index <= 6; index++) config('GEMINI_API_KEY_$index'),
  }.map((key) => key.trim()).where((key) => key.isNotEmpty).toList();

  static GeminiKeyPool get sharedPool {
    final keys = configuredKeys;
    if (_sharedPool == null ||
        _sharedPool!.keys.join('\n') != keys.join('\n')) {
      _sharedPool = GeminiKeyPool(keys);
    }
    return _sharedPool!;
  }

  static String config(String name) {
    const defines = {
      'GEMINI_API_KEY': String.fromEnvironment('GEMINI_API_KEY'),
      'GEMINI_API_KEYS': String.fromEnvironment('GEMINI_API_KEYS'),
      'GEMINI_API_KEY_1': String.fromEnvironment('GEMINI_API_KEY_1'),
      'GEMINI_API_KEY_2': String.fromEnvironment('GEMINI_API_KEY_2'),
      'GEMINI_API_KEY_3': String.fromEnvironment('GEMINI_API_KEY_3'),
      'GEMINI_API_KEY_4': String.fromEnvironment('GEMINI_API_KEY_4'),
      'GEMINI_API_KEY_5': String.fromEnvironment('GEMINI_API_KEY_5'),
      'GEMINI_API_KEY_6': String.fromEnvironment('GEMINI_API_KEY_6'),
      'GEMINI_MODEL': String.fromEnvironment('GEMINI_MODEL'),
      'GEMINI_API_URL': String.fromEnvironment('GEMINI_API_URL'),
    };
    final defined = defines[name] ?? '';
    if (defined.trim().isNotEmpty) return defined.trim();
    return dotenv.isInitialized ? (dotenv.env[name]?.trim() ?? '') : '';
  }

  static bool get isConfigured => configuredKeys.isNotEmpty;

  Future<Map<String, dynamic>?> generate(Map<String, dynamic> profile) async {
    final pool = keyPool ?? sharedPool;
    final available = pool.available();
    if (available.isEmpty) return null;
    final model = config('GEMINI_MODEL').isEmpty
        ? 'gemini-3.5-flash-lite'
        : config('GEMINI_MODEL');
    final base = config('GEMINI_API_URL').isEmpty
        ? 'https://generativelanguage.googleapis.com/v1beta/models'
        : config('GEMINI_API_URL');
    final prompt = '''Return only valid JSON with keys overall and sections.
sections must contain skin_analysis, face, eyes, lips, outfit, accessories,
brands, lens, hair_hijab. Each section is an object of short string values.
Use face.blush_hex, eyes.eyeshadow_hex and lips.hex for the recommended
makeup shades, each formatted as #RRGGBB. No portrait has been provided:
do not claim to have analysed skin or inferred any visual traits.
Create a personalized Pakistani beauty recommendation from this profile:
${jsonEncode(profile)}''';
    final transport = client ?? http.Client();
    final elapsed = Stopwatch()..start();
    try {
      for (final key in available) {
        final remaining = overallTimeout - elapsed.elapsed;
        if (remaining <= Duration.zero) break;
        final timeout = remaining < attemptTimeout ? remaining : attemptTimeout;
        final response = await transport
            .post(
              Uri.parse('$base/$model:generateContent'),
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': key,
              },
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [
                      {'text': prompt},
                    ],
                  },
                ],
                'generationConfig': {'responseMimeType': 'application/json'},
              }),
            )
            .timeout(timeout);
        if ([429, 401, 403, 500, 502, 503, 504].contains(response.statusCode) ||
            (response.statusCode == 400 &&
                response.body.contains('API_KEY_INVALID'))) {
          pool.failed(key, response);
          continue;
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          return null;
        }
        final root = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = root['candidates'];
        if (candidates is! List || candidates.isEmpty) return null;
        final content = (candidates.first as Map)['content'];
        if (content is! Map || content['parts'] is! List) return null;
        final text = (content['parts'] as List)
            .whereType<Map>()
            .where((part) => part['thought'] != true && part['text'] is String)
            .map((part) => part['text'] as String)
            .join();
        if (text.isEmpty) return null;
        final parsed = jsonDecode(text);
        if (parsed is! Map<String, dynamic> ||
            recommendationFromAi(parsed) == null) {
          return null;
        }
        pool.succeeded(key);
        return parsed;
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      if (client == null) transport.close();
    }
  }
}

Recommendation? recommendationFromAi(Map<String, dynamic> value) {
  final overall = value['overall'];
  final rawSections = value['sections'];
  if (overall is! String || overall.trim().isEmpty || rawSections is! Map) {
    return null;
  }
  final sections = <String, Map<String, String>>{};
  for (final key in [
    'skin_analysis',
    'face',
    'eyes',
    'lips',
    'outfit',
    'accessories',
    'brands',
    'lens',
    'hair_hijab',
  ]) {
    final section = rawSections[key];
    if (section is! Map) return null;
    sections[key] = {
      for (final entry in section.entries)
        if (entry.key is String &&
            entry.value is String &&
            (entry.value as String).trim().isNotEmpty)
          entry.key as String: entry.value as String,
    };
    if (sections[key]!.isEmpty) return null;
  }
  return Recommendation(sections, overall, fromAi: true);
}
