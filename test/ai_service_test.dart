import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glow_ai/ai_service.dart';
import 'package:glow_ai/models/profile.dart';
import 'package:glow_ai/services/fallback_recommendation_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() => dotenv.testLoad(fileInput: 'GEMINI_API_KEY=test-key'));
  tearDown(dotenv.clean);
  test(
    'missing configuration uses local recommendations without a request',
    () async {
      dotenv.clean();
      final client = MockClient(
        (_) async => throw StateError('Unexpected HTTP request'),
      );
      expect(await AiService(client: client).generate({}), isNull);
    },
  );
  test(
    'Gemini sends preferences and parses structured recommendations',
    () async {
      final profile = Profile()..event = 'eid';
      final local = const FallbackRecommendationService().create(profile);
      final payload = {'overall': local.overall, 'sections': local.sections};
      final client = MockClient((request) async {
        expect(request.headers['x-goog-api-key'], 'test-key');
        expect(request.url.query, isEmpty);
        final body = jsonDecode(request.body) as Map;
        final prompt = body['contents'][0]['parts'][0]['text'] as String;
        expect(prompt, contains('"event":"eid"'));
        expect(prompt, contains('face.blush_hex'));
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Internal reasoning', 'thought': true},
                    {'text': jsonEncode(payload)},
                  ],
                },
              },
            ],
          }),
          200,
        );
      });
      final response = await AiService(
        client: client,
      ).generate(profile.toJson());
      expect(recommendationFromAi(response!)?.fromAi, isTrue);
    },
  );
  test('unavailable and malformed responses fall back safely', () async {
    for (final response in [
      http.Response('quota exceeded', 429),
      http.Response('{"candidates":[]}', 200),
      http.Response('invalid JSON', 200),
    ]) {
      expect(
        await AiService(client: MockClient((_) async => response)).generate({}),
        isNull,
      );
    }
    expect(recommendationFromAi({'overall': '', 'sections': {}}), isNull);
    expect(recommendationFromAi({'overall': 'A look', 'sections': {}}), isNull);
  });
}
