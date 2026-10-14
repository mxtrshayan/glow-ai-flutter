import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'models/recommendation.dart';

class AiService {
  const AiService();

  Future<Map<String, dynamic>?> generate(Map<String, dynamic> profile) async {
    final key = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
    if (key.isEmpty) return null;
    final model = dotenv.env['GEMINI_MODEL']?.trim().isNotEmpty == true
        ? dotenv.env['GEMINI_MODEL']!.trim()
        : 'gemini-2.0-flash';
    final base = dotenv.env['GEMINI_API_URL']?.trim().isNotEmpty == true
        ? dotenv.env['GEMINI_API_URL']!.trim()
        : 'https://generativelanguage.googleapis.com/v1beta/models';
    final prompt = '''Return only valid JSON with keys overall and sections.
sections must contain skin_analysis, face, eyes, lips, outfit, accessories,
brands, lens, hair_hijab. Each section is an object of short string values.
Create a personalized Pakistani beauty recommendation from this profile:
${jsonEncode(profile)}''';
    try {
      final response = await http
          .post(
            Uri.parse('$base/$model:generateContent?key=$key'),
            headers: {'Content-Type': 'application/json'},
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
          .timeout(const Duration(seconds: 3));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final root = jsonDecode(response.body) as Map<String, dynamic>;
      final text =
          (((root['candidates'] as List?)?.first
                      as Map<String, dynamic>?)?['content']
                  as Map<String, dynamic>?)?['parts']
              is List
          ? ((((root['candidates'] as List).first as Map)['content']
                            as Map)['parts']
                        as List)
                    .first['text']
                as String?
          : null;
      if (text == null) return null;
      final parsed = jsonDecode(text);
      return parsed is Map<String, dynamic> ? parsed : null;
    } catch (_) {
      return null;
    }
  }
}

Recommendation? recommendationFromAi(Map<String, dynamic> value) {
  final overall = value['overall'];
  final rawSections = value['sections'];
  if (overall is! String || rawSections is! Map) return null;
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
        if (entry.key is String && entry.value is String)
          entry.key as String: entry.value as String,
    };
    if (sections[key]!.isEmpty) return null;
  }
  return Recommendation(sections, overall, fromAi: true);
}
