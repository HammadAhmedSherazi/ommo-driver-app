part of 'models.dart';


class PlaceDataModel {
  final String title;
  final String icon;
  final String address;
  final String time;
  final String shopStatus;
  final num distance;
  final double rating;
  final int reviewCount;
  final String storeType;

  const PlaceDataModel({
    required this.title,
    required this.icon,
    required this.address,
    required this.time,
    required this.shopStatus,
    required this.distance,
    required this.rating,
    required this.reviewCount,
    required this.storeType,
  });

  /// Create from JSON
  factory PlaceDataModel.fromJson(Map<String, dynamic> json) {
    return PlaceDataModel(
      title: json['title'] ?? '',
      icon: json['icon'] ?? '', // ✅ Added
      address: json['address'] ?? '',
      time: json['time'] ?? '',
      shopStatus: json['shopStatus'] ?? '',
      distance: (json['distance'] ?? 0) is num
          ? json['distance']
          : num.tryParse(json['distance'].toString()) ?? 0, // safer
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: (json['reviewCount'] ?? 0) is int
          ? json['reviewCount']
          : int.tryParse(json['reviewCount'].toString()) ?? 0,
      storeType: json['storeType'] ?? '',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'icon': icon, // ✅ Added
      'address': address,
      'time': time,
      'shopStatus': shopStatus,
      'distance': distance,
      'rating': rating,
      'reviewCount': reviewCount,
      'storeType': storeType,
    };
  }

  /// CopyWith for immutability
  PlaceDataModel copyWith({
    String? title,
    String? icon,
    String? address,
    String? time,
    String? shopStatus,
    num? distance,
    double? rating,
    int? reviewCount,
    String? storeType,
  }) {
    return PlaceDataModel(
      title: title ?? this.title,
      icon: icon ?? this.icon, // ✅ Added
      address: address ?? this.address,
      time: time ?? this.time,
      shopStatus: shopStatus ?? this.shopStatus,
      distance: distance ?? this.distance,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      storeType: storeType ?? this.storeType,
    );
  }

  @override
  String toString() {
    return 'PlaceDataModel(title: $title, icon: $icon, address: $address, time: $time, shopStatus: $shopStatus, distance: $distance, rating: $rating, reviewCount: $reviewCount, storeType: $storeType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PlaceDataModel &&
        other.title == title &&
        other.icon == icon && // ✅ Added
        other.address == address &&
        other.time == time &&
        other.shopStatus == shopStatus &&
        other.distance == distance &&
        other.rating == rating &&
        other.reviewCount == reviewCount &&
        other.storeType == storeType;
  }

  @override
  int get hashCode {
    return title.hashCode ^
        icon.hashCode ^ // ✅ Added
        address.hashCode ^
        time.hashCode ^
        shopStatus.hashCode ^
        distance.hashCode ^
        rating.hashCode ^
        reviewCount.hashCode ^
        storeType.hashCode;
  }
}
