import 'dart:convert';
import 'dart:developer';

import 'package:here_sdk/core.dart';
import 'package:here_sdk/search.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ommo/models/models.dart';

/// Persisted TTL cache for HERE [Place] results using SDK [Place.serializeCompact] /
/// [Place.deserialize].
///
/// TTLs: text search ~24h, place-by-id ~48h, reverse geocode (map titles) ~24h.
class PlacesHiveCacheService {
  PlacesHiveCacheService._();
  static final PlacesHiveCacheService instance = PlacesHiveCacheService._();

  static const String _boxReverse = 'places_cache_reverse_v1';
  static const String _boxSearch = 'places_cache_search_v1';
  static const String _boxDetails = 'places_cache_details_v1';

  static const Duration reverseGeocodeTtl = Duration(hours: 24);
  static const Duration textSearchTtl = Duration(hours: 24);
  static const Duration placeDetailsTtl = Duration(hours: 48);

  Box<String>? _reverseBox;
  Box<String>? _searchBox;
  Box<String>? _detailsBox;

  Future<void> init() async {
    _reverseBox ??= await Hive.openBox<String>(_boxReverse);
    _searchBox ??= await Hive.openBox<String>(_boxSearch);
    _detailsBox ??= await Hive.openBox<String>(_boxDetails);
  }

  String reverseGeocodeKey(GeoCoordinates c) =>
      '${c.latitude.toStringAsFixed(5)}_${c.longitude.toStringAsFixed(5)}';

  String textSearchKey(String query, GeoCoordinates center) =>
      '${query.trim().toLowerCase()}_${center.latitude.toStringAsFixed(4)}_${center.longitude.toStringAsFixed(4)}';

  String placeDetailsKey(String placeId) => placeId;

  bool _isValid(int? expiresAtMs) =>
      expiresAtMs != null &&
      DateTime.now().millisecondsSinceEpoch < expiresAtMs;

  PlaceDataModel? getReverseGeocodedPlace(GeoCoordinates coords) {
    final box = _reverseBox;
    if (box == null) return null;
    final key = reverseGeocodeKey(coords);
    final raw = box.get(key);
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final exp = j['exp'] as int?;
      if (!_isValid(exp)) {
        box.delete(key);
        return null;
      }

      return PlaceDataModel.fromJson(j['p'] as Map<String, dynamic>);
      // return Place.deserialize(j['p'] as String);
    } catch (_) {
      return null;
    }
  }

  Future<void> putReverseGeocodedPlace(GeoCoordinates coords, PlaceDataModel place) async {
    final box = _reverseBox;
    if (box == null) return;
    final expiresAt =
        DateTime.now().add(reverseGeocodeTtl).millisecondsSinceEpoch;
    final key = reverseGeocodeKey(coords);
    try {
      await box.put(
        key,
        jsonEncode({'exp': expiresAt, 'p': place.toJson()}),
      );
    } catch (_) {}
  }

  List<PlaceDataModel>? getTextSearchPlaces(String query, GeoCoordinates center) {
    final box = _searchBox;
    if (box == null) return null;
    final key = textSearchKey(query, center);
    final raw = box.get(key);
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final exp = j['exp'] as int?;
      if (!_isValid(exp)) {
        box.delete(key);
        return null;
      }
      final items = j['items'] as List<dynamic>;
      final out = <PlaceDataModel>[];
      for (final e in items) {
        out.add(PlaceDataModel.fromJson(e as Map<String, dynamic>));
      }
      return out.isEmpty ? null : out;
    } catch (_) {
      return null;
    }
  }

  Future<void> putTextSearchPlaces(
    String query,
    GeoCoordinates center,
    List<PlaceDataModel> places,
  ) async {
    final box = _searchBox;
    if (box == null || places.isEmpty) return;
    final expiresAt = DateTime.now().add(textSearchTtl).millisecondsSinceEpoch;
    final key = textSearchKey(query, center);
    try {
      final items = places.map((p) => p.toJson()).toList();
      await box.put(key, jsonEncode({'exp': expiresAt, 'items': items}));
    } catch (_) {}
  }

  PlaceDataModel? getPlaceDetails(String placeId) {
    if (placeId.isEmpty) return null;
    final box = _detailsBox;
    if (box == null) return null;
    final key = placeDetailsKey(placeId);
    final raw = box.get(key);
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final exp = j['exp'] as int?;
      if (!_isValid(exp)) {
        box.delete(key);
        return null;
      }
      return PlaceDataModel.fromJson(j['p'] as Map<String, dynamic>);
    } catch (e) {
      log('Error getting place details: ${e.toString()}');
      return null;
    }
  }

  Future<void> putPlaceDetails(String placeId, PlaceDataModel place) async {
    if (placeId.isEmpty) return;
    final box = _detailsBox;
    if (box == null) return;
    final expiresAt =
        DateTime.now().add(placeDetailsTtl).millisecondsSinceEpoch;
    try {
      await box.put(
        placeDetailsKey(placeId),
        jsonEncode({'exp': expiresAt, 'p': place.toJson()}),
      );
    } catch (_) {}
  }
}
