import 'package:here_sdk/mapview.dart';
import 'package:ommo/home/home.dart';
import 'package:ommo/utils/constants/constants.dart';

class TruckNavigationStaticDetails {
  static const List<String> stationList = ["Truck stops", "Weight stations", "Parking", "Rest areas", "Truck washes", "Dealership"];

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

  static const List<PlaceDataModel> places = [
    PlaceDataModel(
      title: "Walmart",
      icon: AppIcons.walmartIcon,
      address: "210 Riverside Drive, New York, NY 10025",
      time: "10 pm",
      shopStatus: "Open",
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
      shopStatus: "Open",
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
      shopStatus: "Close",
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
      shopStatus: "Open",
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
      shopStatus: "Open",
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
      shopStatus: "Close",
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
      shopStatus: "Close",
      distance: 890,
      rating: 5.0,
      reviewCount: 12,
      storeType: "Terminal",
    ),
  ];

  static const List<String> settingChipsList = ["Avoid unpaved roads", "Avoid tunnels", "Avoid ferries", "Avoid restriction Areas"];
  static const List<String> locationOpt = ["Recent", "Saved", "Terminals"];
  static final List<MapViewModel> mapSchemes = [
    MapViewModel(label: "Default", icon: AppImages.defaultMapImg, scheme: MapScheme.normalDay),
    MapViewModel(label: "Satellite", icon: AppImages.satelliteMapImg, scheme: MapScheme.satellite),
    MapViewModel(label: "Hybrid", icon: AppImages.satelliteMapImg, scheme: MapScheme.hybridDay),
  ];
}
