import 'package:hive/hive.dart';

class CacheService {
  static const String BOOKS_CACHE_KEY = 'books_cache';
  static const String CATEGORIES_CACHE_KEY = 'categories_cache';
  static const Duration CACHE_DURATION = Duration(minutes: 15);

  final Box cacheBox;

  CacheService(this.cacheBox);

  Future<void> cacheData(String key, dynamic data) async {
    await cacheBox.put(key, {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  dynamic getCachedData(String key) {
    final cachedData = cacheBox.get(key);
    if (cachedData == null) return null;

    final timestamp = cachedData['timestamp'] as int;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - timestamp > CACHE_DURATION.inMilliseconds) {
      // Cache đã hết hạn
      cacheBox.delete(key);
      return null;
    }

    return cachedData['data'];
  }

  String getCacheKey(String baseKey, [String? param]) {
    return param != null ? '${baseKey}_$param' : baseKey;
  }
}
