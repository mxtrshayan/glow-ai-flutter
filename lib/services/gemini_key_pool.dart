import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Session-only key health. Credentials are never written to logs or preferences.
class GeminiKeyPool {
  GeminiKeyPool(Iterable<String> values, {DateTime Function()? now})
    : keys = values
          .map((key) => key.trim())
          .where((key) => key.isNotEmpty)
          .toSet()
          .toList(),
      _now = now ?? DateTime.now;

  final List<String> keys;
  final DateTime Function() _now;
  final Map<String, DateTime> _unavailableUntil = {};
  int _preferred = 0;

  List<String> available() => [
    for (var offset = 0; offset < keys.length; offset++)
      if (!(_unavailableUntil[keys[(_preferred + offset) % keys.length]]
              ?.isAfter(_now()) ??
          false))
        keys[(_preferred + offset) % keys.length],
  ];

  void succeeded(String key) {
    _unavailableUntil.remove(key);
    _preferred = keys.indexOf(key);
  }

  void failed(String key, http.Response response) {
    var delay = response.statusCode == 429
        ? const Duration(minutes: 1)
        : response.statusCode == 401 || response.statusCode == 403
        ? const Duration(minutes: 5)
        : const Duration(seconds: 5);
    final retryAfter = response.headers['retry-after'];
    if (retryAfter != null) {
      final seconds = int.tryParse(retryAfter);
      if (seconds != null) {
        delay = Duration(seconds: seconds < 1 ? 1 : seconds);
      } else {
        try {
          delay = HttpDate.parse(retryAfter).difference(_now());
        } catch (_) {
          /* use default */
        }
      }
    } else if (response.statusCode == 429) {
      try {
        final body = jsonDecode(response.body) as Map;
        for (final detail in (body['error']?['details'] as List? ?? [])) {
          final retry = detail['retryDelay'];
          if (retry is String && retry.endsWith('s')) {
            final seconds = double.tryParse(
              retry.substring(0, retry.length - 1),
            );
            if (seconds != null) {
              delay = Duration(milliseconds: (seconds * 1000).ceil());
            }
          }
        }
      } catch (_) {
        /* non-JSON provider errors also use the default cooldown */
      }
    }
    if (delay <= Duration.zero) delay = const Duration(seconds: 1);
    _unavailableUntil[key] = _now().add(delay);
  }
}
