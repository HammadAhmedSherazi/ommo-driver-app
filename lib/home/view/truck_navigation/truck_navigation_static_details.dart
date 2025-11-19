import 'package:here_sdk/mapview.dart';
import 'package:ommo/home/home.dart';
import 'package:ommo/utils/constants/constants.dart';

class TruckNavigationStaticDetails {
  static const List<Map<String, String>> stationList = [
    {'name': "Truck stops", 'icon': 'assets/images/Icon (21).png'},
    {'name': "Weight stations", 'icon': 'assets/images/Icon (22).png'},
    {'name': "Parking", 'icon': 'assets/images/Icon (23).png'},
    {'name': "Rest areas", 'icon': 'assets/images/Icon (26).png'},
    {'name': "Truck washes", 'icon': 'assets/images/Icon (25).png'},
    {'name': "More", 'icon': 'assets/images/Icon (24).png'},
  ];

  static const List<Map<String, String>> dealers = [
    {'name': "Speedco", 'icon': 'assets/images/Icon (11).png'},
    {'name': "Thermo King", 'icon': 'assets/images/Icon (12).png'},
    {'name': "Volvo", 'icon': 'assets/images/Vector.png'},
    {'name': "Freightliner", 'icon': 'assets/images/Icon (13).png'},
    {'name': "Mack", 'icon': 'assets/images/Icon (14).png'},
    {'name': "Peterbilt", 'icon': 'assets/images/Icon (15).png'},
    {'name': "Kenworth", 'icon': 'assets/images/Icon (16).png'},
    {'name': "Carrier", 'icon': 'assets/images/Icon (17).png'},
    {'name': "Fleetpride", 'icon': 'assets/images/Icon (18).png'},
    {'name': "International", 'icon': 'assets/images/Icon (19).png'},
    {'name': "Utility Trailers", 'icon': 'assets/images/Icon (20).png'},
  ];

  static const List<Map<String, String>> repairPlaces = [
    {'name': "Truck washes", 'icon': 'assets/images/Icon (4).png'},
    {'name': "Repair Shops", 'icon': 'assets/images/Icon (9).png'},
    {'name': "Tire Care", 'icon': 'assets/images/Icon (10).png'},
  ];

  static const List<Map<String, String>> placeTypes = [
    {"name": "Truck stops", 'icon': 'assets/images/Icon (27).png'},
    {'name': "Weight stations", 'icon': 'assets/images/Icon (22).png'},
    {'name': "Parking", 'icon': 'assets/images/Icon (23).png'},
    {'name': "Rest areas", 'icon': 'assets/images/Icon (26).png'},
    {"name": "Fuel", 'icon': 'assets/images/Icon (1).png'},
    {"name": "Truck Washes", 'icon': 'assets/images/Icon (4).png'},
    {"name": "Restaurant", 'icon': 'assets/images/Icon (2).png'},
    {"name": "Hotel", 'icon': 'assets/images/Icon (5).png'},
    {"name": "Scales", 'icon': 'assets/images/Icon (6).png'},
    {"name": "Gym", 'icon': 'assets/images/Icon (7).png'},
    {"name": "Store", 'icon': 'assets/images/Icon (8).png'},
  ];

  static const Map<String, String> truckInfo = {
    "Height": "12ft 10in",
    "Width": "8ft 5in",
    "Length": "70ft",
    "Total Weight": "70,000lbs",
    "Axle Count": "4",
    "Weight per Axle Group": "20,000lbs",
    "Hazardous Materials": "Flammable",
  };
  static const Map<String, bool> routeRestriction = {
    "Avoid Highways": true,
    "Avoid Tolls": false,
    "Avoid Ferries": false,
    "Avoid Tunnels": false,
    "Avoid Unpaved Roads": false,
  };

  static const List<PlaceDataModel> placess = [
    PlaceDataModel(
      title: "Walmart",
      icon: AppIcons.walmartIcon,
      address: "210 Riverside Drive, New York, NY 10025",
      time: "10 pm",
      shopStatus: true,
      distance: 63,
      rating: 5.0,
      reviewCount: 12,
      storeType: "Store",
    ),
    PlaceDataModel(
      title: "Loves travel stop",
      icon: AppIcons.loveStoreIcon,
      address: "210 Riverside Drive, New York, NY 10025",
      time: "10 pm",
      shopStatus: true,
      distance: 63,
      rating: 5.0,
      reviewCount: 12,
      storeType: "Truck stop",
    ),
    PlaceDataModel(
      title: "CityPark",
      icon: AppIcons.walmartIcon,
      address: "210 Riverside Drive, New York, NY 10025",
      time: "12 pm",
      shopStatus: true,
      distance: 63,
      rating: 5.0,
      reviewCount: 12,
      storeType: "Parking",
    ),
  ];
  static const List<PlaceDataModel> placesss = [
    PlaceDataModel(
      title: "Walmart",
      icon: AppIcons.walmartIcon,
      address: "210 Riverside Drive, New York, NY 10025",
      time: "10 pm",
      shopStatus: true,
      distance: 63,
      rating: 5.0,
      reviewCount: 12,
      storeType: "Store",
    ),
    PlaceDataModel(
      title: "Loves travel stop",
      icon: AppIcons.loveStoreIcon,
      address: "210 Riverside Drive, New York, NY 10025",
      time: "10 pm",
      shopStatus: true,
      distance: 63,
      rating: 5.0,
      reviewCount: 12,
      storeType: "Truck stop",
    ),
    PlaceDataModel(
      title: "CityPark",
      icon: AppIcons.walmartIcon,
      address: "210 Riverside Drive, New York, NY 10025",
      time: "12 pm",
      shopStatus: true,
      distance: 63,
      rating: 5.0,
      reviewCount: 12,
      storeType: "Parking",
    ),
    PlaceDataModel(
      title: "Walmart",
      icon: AppIcons.walmartIcon,
      address: "210 Riverside Drive, New York, NY 10025",
      time: "10 pm",
      shopStatus: true,
      distance: 63,
      rating: 5.0,
      reviewCount: 12,
      storeType: "Store",
    ),
    PlaceDataModel(
      title: "Loves travel stop",
      icon: AppIcons.loveStoreIcon,
      address: "210 Riverside Drive, New York, NY 10025",
      time: "10 pm",
      shopStatus: true,
      distance: 63,
      rating: 5.0,
      reviewCount: 12,
      storeType: "Truck stop",
    ),
    PlaceDataModel(
      title: "CityPark",
      icon: AppIcons.walmartIcon,
      address: "210 Riverside Drive, New York, NY 10025",
      time: "12 pm",
      shopStatus: true,
      distance: 63,
      rating: 5.0,
      reviewCount: 12,
      storeType: "Parking",
    ),
  ];

  static const List<PlaceDataModel> terminals = [
    PlaceDataModel(
      title: "LogiCorp Terminal",
      icon: AppIcons.orderBoxIcon,
      address: "1234 Industrial Way, Chicago, IL 60601",
      time: "12 pm",
      shopStatus: true,
      distance: 150,
      rating: 5.0,
      reviewCount: 12,
      storeType: "Terminal",
    ),
    PlaceDataModel(
      title: "TransLine Depot",
      icon: AppIcons.orderBoxIcon,
      address: "5678 Freight Blvd, Los Angeles, CA 90001",
      time: "12 pm",
      shopStatus: true,
      distance: 1250,
      rating: 5.0,
      reviewCount: 12,
      storeType: "Terminal",
    ),
    PlaceDataModel(
      title: "FastMove Terminal",
      icon: AppIcons.orderBoxIcon,
      address: "210 Riverside Drive, New York, NY 10025",
      time: "12 pm",
      shopStatus: false,
      distance: 2005,
      rating: 5.0,
      reviewCount: 12,
      storeType: "Terminal",
    ),
    PlaceDataModel(
      title: "Eastern Freight Hub",
      icon: AppIcons.orderBoxIcon,
      address: "210 Riverside Drive, New York, NY 10025",
      time: "12 pm",
      shopStatus: false,
      distance: 890,
      rating: 5.0,
      reviewCount: 12,
      storeType: "Terminal",
    ),
  ];

  static const List<String> settingChipsList = [
    "Avoid unpaved roads",
    "Avoid tunnels",
    "Avoid ferries",
    "Avoid restriction Areas",
  ];

  static const List<String> locationOpt = ["Recent", "Saved", "Terminals"];
  static const List<String> placeTypeTabOpt = ["All", "Saved", "Fuel deals"];
  static final List<MapViewModel> mapSchemes = [
    MapViewModel(
      label: "Default",
      icon: AppImages.defaultMapImg,
      scheme: MapScheme.normalDay,
    ),
    MapViewModel(
      label: "Satellite",
      icon: AppImages.satelliteMapImg,
      scheme: MapScheme.satellite,
    ),
    // MapViewModel(label: "Hybrid", icon: AppImages.satelliteMapImg, scheme: MapScheme.hybridDay),
  ];
}
