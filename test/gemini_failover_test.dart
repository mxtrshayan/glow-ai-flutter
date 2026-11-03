import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glow_ai/ai_service.dart';
import 'package:glow_ai/models/profile.dart';
import 'package:glow_ai/services/fallback_recommendation_service.dart';
import 'package:glow_ai/services/gemini_key_pool.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response success() {
  final look = const FallbackRecommendationService().create(
    Profile()..event = 'eid',
  );
  return http.Response(
    jsonEncode({
      'candidates': [
        {
          'content': {
            'parts': [
              {
                'text': jsonEncode({
                  'overall': look.overall,
                  'sections': look.sections,
                }),
              },
            ],
          },
        },
      ],
    }),
    200,
  );
}

void main() {
  tearDown(dotenv.clean);
  test(
    'comma, numbered and legacy key configuration deduplicates credentials',
    () {
      dotenv.testLoad(
        fileInput:
            'GEMINI_API_KEYS=first, second\nGEMINI_API_KEY=first\nGEMINI_API_KEY_3=third',
      );
      expect(AiService.configuredKeys, ['first', 'second', 'third']);
      expect(AiService.isConfigured, isTrue);
    },
  );
  test(
    'quota failure rotates once, honors Retry-After, and keeps the working key',
    () async {
      var now = DateTime.utc(2026, 11, 3);
      final pool = GeminiKeyPool(['quota', 'working'], now: () => now);
      final used = <String>[];
      final service = AiService(
        keyPool: pool,
        client: MockClient((request) async {
          final key = request.headers['x-goog-api-key']!;
          used.add(key);
          return key == 'quota'
              ? http.Response('{}', 429, headers: {'retry-after': '120'})
              : success();
        }),
      );
      expect(await service.generate({}), isNotNull);
      expect(used, ['quota', 'working']);
      expect(pool.available(), ['working']);
      await service.generate({});
      expect(used, ['quota', 'working', 'working']);
      now = now.add(const Duration(seconds: 121));
      expect(pool.available(), ['working', 'quota']);
    },
  );
  test(
    'all six quota failures stop and cached cooldown avoids another request',
    () async {
      final pool = GeminiKeyPool(List.generate(6, (i) => 'key-$i'));
      var calls = 0;
      final service = AiService(
        keyPool: pool,
        client: MockClient((_) async {
          calls++;
          return http.Response('{}', 429);
        }),
      );
      expect(await service.generate({}), isNull);
      expect(calls, 6);
      expect(await service.generate({}), isNull);
      expect(calls, 6);
      expect(
        const FallbackRecommendationService().create(Profile()).sections,
        hasLength(9),
      );
    },
  );
  test(
    'disabled credentials and temporary server failures use another key',
    () async {
      for (final status in [401, 403, 500, 503]) {
        var calls = 0;
        final service = AiService(
          keyPool: GeminiKeyPool(['first', 'second']),
          client: MockClient((_) async {
            calls++;
            return calls == 1 ? http.Response('{}', status) : success();
          }),
        );
        expect(await service.generate({}), isNotNull);
        expect(calls, 2);
      }
    },
  );
  test(
    'network timeout is bounded and falls back without exhausting every key',
    () async {
      final response = Completer<http.Response>();
      var calls = 0;
      final service = AiService(
        keyPool: GeminiKeyPool(['first', 'second']),
        attemptTimeout: const Duration(milliseconds: 20),
        overallTimeout: const Duration(milliseconds: 30),
        client: MockClient((_) {
          calls++;
          return response.future;
        }),
      );
      expect(
        await service.generate({}).timeout(const Duration(seconds: 1)),
        isNull,
      );
      expect(calls, 1);
      response.complete(success());
    },
  );
  test(
    'invalid API key error rotates without treating every 400 as a key error',
    () async {
      var calls = 0;
      final service = AiService(
        keyPool: GeminiKeyPool(['invalid', 'working']),
        client: MockClient((_) async {
          calls++;
          return calls == 1
              ? http.Response(
                  '{"error":{"details":[{"reason":"API_KEY_INVALID"}]}}',
                  400,
                )
              : success();
        }),
      );
      expect(await service.generate({}), isNotNull);
      expect(calls, 2);
    },
  );
  test('provider RetryInfo cooldown is respected', () {
    var now = DateTime.utc(2026, 11, 3);
    final pool = GeminiKeyPool(['only'], now: () => now);
    pool.failed(
      'only',
      http.Response(
        jsonEncode({
          'error': {
            'details': [
              {
                '@type': 'type.googleapis.com/google.rpc.RetryInfo',
                'retryDelay': '90s',
              },
            ],
          },
        }),
        429,
      ),
    );
    now = now.add(const Duration(seconds: 60));
    expect(pool.available(), isEmpty);
    now = now.add(const Duration(seconds: 31));
    expect(pool.available(), ['only']);
  });
}
