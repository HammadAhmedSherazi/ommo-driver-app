import 'package:hive/hive.dart';
import 'package:ommo/services/hive/recent_search/model/recent_search_model.dart';

class RecentSearchService {
  static const String boxName = "recent_search_box";

  Box<RecentSearchModel> get _box => Hive.box<RecentSearchModel>(boxName);

  Future<void> addSearch(RecentSearchModel item) async {
    // Remove duplicate if exists
    final duplicates = _box.values.where(
      (e) => e.latitude == item.latitude && e.longitude == item.longitude,
    );
    for (var d in duplicates) await d.delete();

    // Limit max entries
    if (_box.length >= 5) {
      await _box.getAt(0)?.delete(); // remove oldest
    }

    await _box.add(item);
  }

  List<RecentSearchModel> getRecentSearches() {
    final items = _box.values.toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // newest first
    return items;
  }

  Future<void> clearAll() async => _box.clear();

  Future<void> removeAt(int index) async {
    await _box.deleteAt(index);
  }
}
