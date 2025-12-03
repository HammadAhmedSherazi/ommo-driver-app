import 'package:hive/hive.dart';

part 'recent_search_model.g.dart';

@HiveType(typeId: 0)
class RecentSearchModel extends HiveObject {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String address;

  @HiveField(2)
  final double latitude;

  @HiveField(3)
  final double longitude;

  @HiveField(4)
  final DateTime timestamp;
  
  @HiveField(5)
  final bool isBussiness;

  RecentSearchModel({
    required this.title,
    required this.isBussiness,
    required this.address,
    required this.latitude,
    required this.longitude,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
