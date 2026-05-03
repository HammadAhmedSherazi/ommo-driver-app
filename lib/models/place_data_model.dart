part of 'models.dart';

class PlaceDataModel {
  final String id;
  final String title;
  final String subtitle;
  final String address;
  final double latitude;
  final double longitude;
  final String storeType;
  final String? website;
  final String? phoneNumber;
  final String? category;
  final List<String>? amenities;
  final String? icon;
  final String? networkImage;
  final String? time;
  final bool? shopStatus;
  final bool isBusiness;
  // final num? distance;
  final double? rating;
  final int? reviewCount;
  final num? distanceInMeters;

  String get distanceInMiles =>
      '${((distanceInMeters ?? 0) / 1609).toStringAsFixed(1)} mi';

  const PlaceDataModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.address,
    required this.longitude,
    required this.latitude,
    required this.storeType,
    this.isBusiness = false,
    this.amenities,
    this.icon,
    this.networkImage = '',
    this.distanceInMeters,
    this.website,
    this.phoneNumber,
    this.category,
    this.time,
    this.shopStatus,
    // this.distance,
    this.rating,
    this.reviewCount,
  });

  GeoCoordinates get geoCoordinates => GeoCoordinates(latitude, longitude);

  /// Create from JSON
  factory PlaceDataModel.fromJson(Map<String, dynamic> json) {
    return PlaceDataModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      address: json['address'] ?? '',
      storeType: json['storeType'] ?? '',
      amenities: (json['amenities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ,
      distanceInMeters: (json['distanceInMeters'] ?? 0) is num
          ? (json['distanceInMeters'] ?? 0.0)
          : num.tryParse(json['distanceInMeters'].toString()) ?? 0,
      website: json['website'] ,
      phoneNumber: json['phoneNumber'],
      category: json['category'],
      icon: json['icon'],
      networkImage: json['networkImage'] ,
      time: json['time'],
      isBusiness: json['isBusiness'] ?? false,
      shopStatus: json['shopStatus'],
      // distance: (json['distance'] ?? 0) is num
      //     ? (json['distance'] ?? 0.0)
      //     : num.tryParse(json['distance'].toString()) ?? 0,
      rating: json['rating'] ,
      reviewCount:json['reviewCount'] ,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amenities': amenities,
      'distanceInMeters': distanceInMeters,
      'website': website,
      'phoneNumber': phoneNumber,
      'category': category,
      'subtitle': subtitle,
      'id': id,
      'icon': icon,
      'address': address,
      'networkImage': networkImage,
      'time': time,
      'shopStatus': shopStatus,
      // 'distance': distance,
      'latitude': latitude,
      'longitude': longitude,
      'isBusiness': isBusiness,
      'rating': rating,
      'reviewCount': reviewCount,
      'storeType': storeType,
    };
  }

  /// CopyWith for immutability
  PlaceDataModel copyWith({
    String? formattedTitle,
    String? formattedSubtitle,
    String? icon,
    String? address,
    String? networkImage,
    String? time,
    bool? shopStatus,
    // num? distance,
    double? latitude,
    List<String>? amenities,
    double? longitude,
    bool? isBusiness,
    num? distanceInMeters,
    String? website,
    String? phoneNumber,
    String? category,

    double? rating,
    int? reviewCount,
    String? storeType,
  }) {
    return PlaceDataModel(
      id: id,
      title: formattedTitle ?? this.title,
      subtitle: formattedSubtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      amenities: amenities ?? this.amenities,
      distanceInMeters: distanceInMeters ?? this.distanceInMeters,
      website: website ?? this.website,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isBusiness: isBusiness ?? this.isBusiness,
      networkImage: networkImage ?? this.networkImage,
      address: address ?? this.address,
      time: time ?? this.time,
      shopStatus: shopStatus ?? this.shopStatus,
      // distance: distance ?? this.distance,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      storeType: storeType ?? this.storeType,
    );
  }

  @override
  String toString() {
    return 'PlaceDataModel(id: $id, title: $title, icon: $icon, address: $address, time: $time, shopStatus: $shopStatus, distance: $distanceInMeters, rating: $rating, reviewCount: $reviewCount, storeType: $storeType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PlaceDataModel &&
        other.id == id &&
        other.amenities == amenities &&
        other.distanceInMeters == distanceInMeters &&
        other.website == website &&
        other.phoneNumber == phoneNumber &&
        other.category == category &&
        other.title == title &&
        other.subtitle == subtitle &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.isBusiness == isBusiness &&
        other.icon == icon && // ✅ Added
        other.networkImage == networkImage && // ✅ Added
        other.address == address &&
        other.time == time &&
        other.shopStatus == shopStatus &&
        // other.distance == distance &&
        other.rating == rating &&
        other.reviewCount == reviewCount &&
        other.storeType == storeType;
  }

  @override
  int get hashCode {
    return title.hashCode ^
        amenities.hashCode ^
        distanceInMeters.hashCode ^
        website.hashCode ^
        phoneNumber.hashCode ^
        category.hashCode ^
        icon.hashCode ^
        subtitle.hashCode ^
        address.hashCode ^
        networkImage.hashCode ^
        time.hashCode ^
        shopStatus.hashCode ^
        // distance.hashCode ^
        rating.hashCode ^
        reviewCount.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        isBusiness.hashCode ^
        id.hashCode ^
        storeType.hashCode;
  }
}
