import 'package:hive/hive.dart';

class PlacesCacheService {
  PlacesCacheService._internal();
  static final PlacesCacheService _instance = PlacesCacheService._internal();
  factory PlacesCacheService() {
    return _instance;
  }

  final searchTTL = 48 * 60 * 60 * 1000; // 48 hour
  final geoTTL = 48 * 60 * 60 * 1000; // 48 hours
  final placeTTL = 48 * 60 * 60 * 1000; // 48 hours

  Future<void> init() async {
    await Hive.openBox('place_search_cache');
    await Hive.openBox('geocode_cache');
    await Hive.openBox('place_details_cache');

    clean(Hive.box('place_search_cache'), searchTTL);
    clean(Hive.box('geocode_cache'), geoTTL);
    clean(Hive.box('place_details_cache'), placeTTL);
  }

  getSearchCache(String key) {
    final box = Hive.box('place_search_cache');
    return get(box, key, searchTTL);
  }

  getGeocodeCache(String key) {
    final box = Hive.box('geocode_cache');
    return get(box, key, geoTTL);
  }

  getPlaceDetailsCache(String key) {
    final box = Hive.box('place_details_cache');
    return get(box, key, placeTTL);
  }

  void setSearchCache(String key, dynamic data) {
    final box = Hive.box('place_search_cache');
    set(box, key, data);
  }

  void setGeocodeCache(String key, dynamic data) {
    final box = Hive.box('geocode_cache');
    set(box, key, data);
  }

  void setPlaceDetailsCache(String key, dynamic data) {
    final box = Hive.box('place_details_cache');
    set(box, key, data);
  }

  dynamic get(Box box, String key, int ttl) {
    final cached = box.get(key);

    if (cached == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    final timestamp = cached["timestamp"];

    if (timestamp == null || now - timestamp > ttl) {
      box.delete(key);
      return null;
    }

    return cached["data"];
  }

  void set(Box box, String key, dynamic data) {
    box.put(key, {
      "data": data,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    });
  }

  void clean(Box box, int ttl) {
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var key in box.keys) {
      final item = box.get(key);

      if (item is Map && item["timestamp"] != null) {
        if (now - item["timestamp"] > ttl) {
          box.delete(key);
        }
      }
    }
  }
}
