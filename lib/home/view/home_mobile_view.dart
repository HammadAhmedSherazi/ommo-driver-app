import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:here_sdk/core.dart' hide Location;
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/search.dart';
import 'package:ommo/custom_widget/custom_accordion_widget.dart';
import 'package:ommo/custom_widget/custom_widget.dart';
import 'package:ommo/home/cubit/map_cubit.dart';
import 'package:ommo/home/cubit/map_state.dart';
import 'package:ommo/home/view/map_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:ommo/utils/extension/route_extension.dart';
import 'package:ommo/utils/utils.dart';

import '../../map_sdk/truck_guidance_example.dart';
import '../home.dart';

class HomeMobileView extends StatefulWidget {
  const HomeMobileView({super.key});

  @override
  State<HomeMobileView> createState() => _HomeMobileViewState();
}

class _HomeMobileViewState extends State<HomeMobileView> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<TextEditingController> textController = [TextEditingController(text: "Start My Current Location")];
  final List<FocusNode> focusNode = [FocusNode()];

  HereMapController? _hereMapController;
  final List<String> stationList = ["Truck stops", "Weight stations", "Parking", "Rest areas", "Truck washes", "Dealership"];
  // late MapMarker _userMarker;
  // late MapPolygon _accuracyCircle;
  final Map<String, String> truckInfo = {
    "Height": "12ft 10in",
    "Width": "8ft 5in",
    "Length": "70ft",
    "Total Weight": "70,000lbs",
    "Axle Count": "4",
    "Weight per Axle Group": "20,000lbs",
    "Hazardous Materials": "Flammable",
  };
  final Map<String, bool> routeRestriction = {
    "Avoid Highways": true,
    "Avoid Tolls": false,
    "Avoid Ferries": false,
    "Avoid Tunnels": false,
    "Avoid Unpaved Roads": false,
  };

  final List<PlaceDataModel> places = [
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

  final List<PlaceDataModel> terminals = [
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
  bool showMore = false, changeMapScheme = false;
  int selectIndexMapView = 0;
  final List<String> settingChipsList = ["Avoid unpaved roads", "Avoid tunnels", "Avoid ferries", "Avoid restriction Areas"];
  TruckGuidanceExample? _truckGuidanceExample;
  PlaceDataModel? place;

  final List<String> locationOpt = ["Recent", "Saved", "Terminals"];
  int selectLocationOpt = 0;
  final List<MapViewModel> mapSchemes = [
    MapViewModel(label: "Default", icon: AppImages.defaultMapImg, scheme: MapScheme.normalDay),
    MapViewModel(label: "Satellite", icon: AppImages.satelliteMapImg, scheme: MapScheme.satellite),
    MapViewModel(label: "Hybrid", icon: AppImages.satelliteMapImg, scheme: MapScheme.hybridDay),
  ];
  _setRestrictionIcon(String key) {
    switch (key) {
      case "Avoid Highways":
        return AppIcons.roadIcon;
      case "Avoid Tolls":
        return AppIcons.flyoverIcon;
      case "Avoid Ferries":
        return AppIcons.directionBoatIcon;
      case "Avoid Tunnels":
        return AppIcons.subwayIcon;
      case "Avoid Unpaved Roads":
        return AppIcons.unpavedRoadIcon;
    }
  }

  void openDialog() {
    Map<String, bool> amenitiesList = {
      "Parking": false,
      "Overnight parking": false,
      "Free spots": false,
      "Paid spots": false,
      "Wi-Fi": false,
      "Showers": false,
      "Scales": false,
      "Tire care": false,
      "Transflo express": false,
      "Bulk DEF": false,
      "Oneside GYM": false,
      "Fax scan": false,
      "Pool": false,
    };
    File? selectedImage;
    showMore = false;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white,
          child: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                height: context.screenHeight * 0.8,
                width: context.screenWidth,

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: ListView(
                        shrinkWrap: true,
                        physics: BouncingScrollPhysics(),
                        padding: EdgeInsets.all(24),
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Add a place", style: AppTextTheme().headingText),
                              IconButton(
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity(horizontal: -4.0, vertical: -4.0),
                                onPressed: () {
                                  context.popPage();
                                },
                                icon: Icon(Icons.close, color: Color(0xff8C93A4)),
                              ),
                            ],
                          ),
                          24.h,
                          Text("Name", style: AppTextTheme().bodyText.copyWith(fontSize: 16)),
                          7.h,
                          CustomTextfieldWidget(hintText: "Enter place name"),
                          24.h,
                          Text("Address", style: AppTextTheme().bodyText.copyWith(fontSize: 16)),
                          7.h,
                          CustomTextfieldWidget(hintText: "Enter address", suffixIcon: SvgPicture.asset(AppIcons.navigationOutlineIcon)),
                          24.h,
                          SizedBox(
                            height: 200,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              // child: MapView(),
                              child: HereMap(
                                onMapCreated: (mapController) {
                                  // Load the map scene using a map scheme to render the map with.
                                  mapController.mapScene.loadSceneForMapScheme(MapScheme.normalDay, (MapError? error) {
                                    if (error == null) {
                                      mapController.mapScene.enableFeatures({MapFeatures.lowSpeedZones: MapFeatureModes.lowSpeedZonesAll});
                                      // _truckGuidanceExample =
                                      //     TruckGuidanceExample(_showDialog, hereMapController);
                                      // _truckGuidanceExample!.setUICallback(this);
                                    } else {}
                                  });
                                },
                              ),
                            ),
                          ),
                          if (showMore) ...[
                            24.h,
                            Text("Phone number", style: AppTextTheme().bodyText.copyWith(fontSize: 16)),
                            7.h,
                            CustomTextfieldWidget(hintText: "Enter number", keyboardType: TextInputType.phone),
                            24.h,
                            Text("Website", style: AppTextTheme().bodyText.copyWith(fontSize: 16)),
                            7.h,
                            CustomTextfieldWidget(hintText: "Paste link", keyboardType: TextInputType.phone),
                            24.h,
                            Text("Opening hours", style: AppTextTheme().bodyText.copyWith(fontSize: 16)),
                            7.h,
                            CustomTextfieldWidget(
                              suffixIcon: Icon(Icons.arrow_forward_ios, size: 17),
                              hintText: "Opening hours ",
                              onTap: () {
                                openHourDialog();
                              },
                            ),
                            24.h,
                            Text("Brand logo (optional)", style: AppTextTheme().bodyText.copyWith(fontSize: 16)),
                            7.h,
                            GestureDetector(
                              onTap: () async {
                                final picker = ImagePicker();

                                // Show choice dialog
                                final source = await showModalBottomSheet<ImageSource>(
                                  context: context,
                                  builder: (context) {
                                    return SafeArea(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(vertical: AppTheme.horizontalPadding),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              leading: const Icon(Icons.camera_alt),
                                              title: const Text('Take a photo'),
                                              onTap: () => Navigator.pop(context, ImageSource.camera),
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.photo_library),
                                              title: const Text('Choose from gallery'),
                                              onTap: () => Navigator.pop(context, ImageSource.gallery),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );

                                // If user canceled dialog
                                if (source == null) return;

                                // Pick image from selected source
                                final picked = await picker.pickImage(source: source);
                                if (picked != null) {
                                  final imageFile = File(picked.path);
                                  setState(() {
                                    selectedImage = imageFile;
                                  });
                                }
                              },
                              child: selectedImage == null
                                  ? Row(
                                      spacing: 5,
                                      children: [
                                        Icon(Icons.add),
                                        Text("Add Logo", style: AppTextTheme().bodyText.copyWith(color: AppColorTheme().primary)),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Container(
                                          width: 56,
                                          height: 56,
                                          padding: EdgeInsets.all(3),
                                          alignment: Alignment.topCenter,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(5),
                                            image: DecorationImage(image: FileImage(File(selectedImage!.path)), fit: BoxFit.cover),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    selectedImage = null;
                                                  });
                                                },
                                                child: CircleAvatar(
                                                  backgroundColor: Colors.white,
                                                  radius: 8,
                                                  child: Icon(Icons.close, size: 10, color: Colors.black),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            24.h,
                            Text("Amenities", style: AppTextTheme().bodyText.copyWith(fontSize: 16)),
                            7.h,
                            ...List.generate(
                              amenitiesList.length,
                              (index) => Row(
                                children: [
                                  Transform.scale(
                                    scale: 0.6,
                                    child: Switch.adaptive(
                                      padding: EdgeInsets.zero,

                                      value: amenitiesList.entries.elementAt(index).value,
                                      onChanged: (v) {
                                        setState(() {
                                          amenitiesList.update(amenitiesList.entries.elementAt(index).key, (bol) => !bol);
                                        });
                                      },
                                    ),
                                  ),
                                  Text(amenitiesList.entries.elementAt(index).key, style: AppTextTheme().bodyText),
                                ],
                              ),
                            ),
                          ],
                          if (!showMore) ...[
                            24.h,
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  showMore = true;
                                });
                              },
                              child: Row(
                                spacing: 5,
                                children: [
                                  Text("Add more details", style: AppTextTheme().bodyText.copyWith(color: AppColorTheme().primary)),
                                  Icon(Icons.keyboard_arrow_down, size: 17),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsetsGeometry.all(AppTheme.horizontalPadding),
                      child: CustomButtonWidget(
                        title: "Add place",
                        onPressed: () {
                          context.popPage();
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void openHourDialog() {
    Map<String, bool> days = {
      "Monday": false,
      "Tuesday": false,
      "Wednesday": false,
      "Thursday": false,
      "Friday": false,
      "Saturday": true,
      "Sunday": true,
    };

    List<TextEditingController> openTextEditController = List.generate(days.length, (index) => TextEditingController());

    List<TextEditingController> closeTextEditController = List.generate(days.length, (index) => TextEditingController());

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white,
          child: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                height: context.screenHeight * 0.8,
                width: context.screenWidth,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.all(24),
                        physics: BouncingScrollPhysics(),
                        children: [
                          // header row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () => context.popPage(),
                                icon: Icon(Icons.arrow_back, color: Colors.black),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity(horizontal: -4.0, vertical: -4.0),
                              ),
                              Text("Opening hours", style: AppTextTheme().headingText),
                              IconButton(
                                onPressed: () => context.popPage(),
                                icon: Icon(Icons.close, color: Color(0xff8C93A4)),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity(horizontal: -4.0, vertical: -4.0),
                              ),
                            ],
                          ),

                          // day rows
                          ...List.generate(days.length, (index) {
                            final dayName = days.keys.elementAt(index);
                            final isOpen = days.values.elementAt(index);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 24),
                                Row(
                                  children: [
                                    Text(dayName, style: AppTextTheme().bodyText),
                                    Spacer(),
                                    Text("Closed", style: AppTextTheme().lightText),
                                    Transform.scale(
                                      scale: 0.6,
                                      child: Switch.adaptive(
                                        value: isOpen,
                                        onChanged: (v) {
                                          setState(() {
                                            days[dayName] = v;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextfieldWidget(
                                        hintText: "--:--",

                                        controller: openTextEditController[index],
                                        onTap: () async {
                                          final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                          if (!context.mounted) return;
                                          if (picked != null) {
                                            openTextEditController[index].text = picked.format(context);
                                          }
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    Expanded(
                                      child: CustomTextfieldWidget(
                                        hintText: "--:--",

                                        controller: closeTextEditController[index],
                                        onTap: () async {
                                          final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                          if (!context.mounted) return;
                                          if (picked != null) {
                                            closeTextEditController[index].text = picked.format(context);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(AppTheme.horizontalPadding),
                      child: CustomButtonWidget(
                        title: "Save",
                        onPressed: () {
                          // here you can collect open/close times per day
                          for (int i = 0; i < days.length; i++) {
                            print(
                              "${days.keys.elementAt(i)}: ${openTextEditController[i].text} - ${closeTextEditController[i].text}, open=${days.values.elementAt(i)}",
                            );
                          }
                          context.popPage();
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // void _showUserLocation(HereMapController controller, GeoCoordinates coords) {
  //   // Create marker (blue dot)
  //   MapImage userImage = MapImage.withFilePathAndWidthAndHeight(
  //     AppIcons.myLocIcon,
  //     40,
  //     40,
  //   ); // add your own icon
  //   _userMarker = MapMarker(coords, userImage);
  //   controller.mapScene.addMapMarker(_userMarker);

  //   // Create accuracy circle
  //   // GeoCircle geoCircle = GeoCircle(coords, accuracy); // accuracy in meters
  //   // GeoCircleStyle circleStyle = GeoCircleStyle()
  //   //   ..fillColor = Color.fromARGB(80, 0, 0, 255)  // semi-transparent blue
  //   //   ..strokeColor = Color.fromARGB(120, 0, 0, 200)
  //   //   ..strokeWidth = 2;

  //   // _accuracyCircle = MapPolygon(geoCircle., circleStyle);
  //   // controller.mapScene.addMapPolygon(_accuracyCircle);

  //   // Center camera
  //   controller.camera.lookAtPoint(coords);
  // }

  void _enableSafetyCameras(HereMapController controller) {
    controller.mapScene.enableFeatures({MapFeatures.safetyCameras: MapFeatureModes.safetyCamerasAll});
  }

  final Location _location = Location();

  Future<GeoCoordinates?> _getCurrentLocation() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return null;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return null;
    }

    LocationData locationData = await _location.getLocation();
    return GeoCoordinates(locationData.latitude!, locationData.longitude!);
  }

  Future<void> _showDialog(String title, String message) async {
    // return showDialog<void>(
    //   context: context,
    //   barrierDismissible: false,
    //   builder: (BuildContext context) {
    //     return AlertDialog(
    //       title: Text(title),
    //       content: SingleChildScrollView(
    //         child: ListBody(
    //           children: <Widget>[
    //             Text(message),
    //           ],
    //         ),
    //       ),
    //       actions: <Widget>[
    //         TextButton(
    //           child: const Text('OK'),
    //           onPressed: () {
    //             Navigator.of(context).pop();
    //           },
    //         ),
    //       ],
    //     );
    //   },
    // );
  }
  final TextEditingController searchTextEditController = TextEditingController();
  FocusNode searchFieldFocusNode = FocusNode();
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      if (mounted) {
        final mapCubit = context.read<MapCubit>();
        final loc = await _getCurrentLocation();

        // _showUserLocation(_hereMapController!, loc!);
        if (loc != null && mapCubit.state.startCoordinates == null) {
          mapCubit.setCurrentLocationPoint(loc);
        }
      }
    });
    _tabController = TabController(length: locationOpt.length, vsync: this);
    textController.add(searchTextEditController);
    focusNode.add(FocusNode());
    searchFieldFocusNode.addListener(() {
      setState(() {});
    });
  }

  void openTruckSetting() {
    Helpers.openBottomSheet(
      context: context,
      child: SizedBox(
        height: context.screenHeight * 0.80,

        child: Column(
          children: [
            Expanded(
              child: ListView(
                // physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: AppTheme.horizontalPadding),
                children: [
                  Row(
                    spacing: 10,
                    children: [
                      GestureDetector(
                        onTap: () {
                          context.popPage();
                        },
                        child: CircleAvatar(
                          radius: 25,
                          backgroundColor: AppColorTheme().whiteShade,
                          child: Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
                        ),
                      ),
                      Text("Truck Dimensions", style: AppTextTheme().subHeadingText.copyWith(fontWeight: AppFontWeight.semiBold, fontSize: 20)),
                    ],
                  ),
                  20.h,
                  DashedLine(),
                  20.h,
                  Row(
                    spacing: 10,
                    children: [
                      SvgPicture.asset(AppIcons.lengthIcon),
                      SizedBox(
                        width: context.screenWidth * 0.24,
                        child: Text("Length", style: AppTextTheme().lightText.copyWith(fontSize: 16)),
                      ),

                      Expanded(
                        child: CustomTextfieldWidget(hintText: "00'", keyboardType: TextInputType.number),
                      ),
                      Expanded(
                        child: CustomTextfieldWidget(hintText: "0''", keyboardType: TextInputType.number),
                      ),
                    ],
                  ),
                  5.h,
                  Row(
                    spacing: 10,
                    children: [
                      SvgPicture.asset(AppIcons.heightIcon),
                      SizedBox(
                        width: context.screenWidth * 0.24,
                        child: Text("Height", style: AppTextTheme().lightText.copyWith(fontSize: 16)),
                      ),

                      Expanded(
                        child: CustomTextfieldWidget(hintText: "00'", keyboardType: TextInputType.number),
                      ),
                      Expanded(
                        child: CustomTextfieldWidget(hintText: "0''", keyboardType: TextInputType.number),
                      ),
                    ],
                  ),
                  5.h,
                  Row(
                    spacing: 10,
                    children: [
                      SvgPicture.asset(AppIcons.widthIcon),
                      SizedBox(
                        width: context.screenWidth * 0.24,
                        child: Text("Width", style: AppTextTheme().lightText.copyWith(fontSize: 16)),
                      ),

                      Expanded(
                        child: CustomTextfieldWidget(hintText: "00'", keyboardType: TextInputType.number),
                      ),
                      Expanded(
                        child: CustomTextfieldWidget(hintText: "0''", keyboardType: TextInputType.number),
                      ),
                    ],
                  ),
                  5.h,

                  Row(
                    spacing: 10,
                    children: [
                      SvgPicture.asset(AppIcons.axleIcon),
                      SizedBox(
                        width: context.screenWidth * 0.24,
                        child: Text("Axle Count", style: AppTextTheme().lightText.copyWith(fontSize: 16)),
                      ),

                      Expanded(
                        child: CustomDropDown<int>(
                          placeholderText: "Select Axle",
                          options: List.generate(5, (index) => CustomDropDownOption(value: index + 1, displayOption: "${index + 1} Axle")),
                          value: 2, // default selected value (optional)
                          onChanged: (selected) {
                            print("Selected axle: $selected");
                          },
                        ),
                      ),
                    ],
                  ),
                  5.h,
                  Row(
                    spacing: 10,
                    children: [
                      SvgPicture.asset(AppIcons.weightScaleIcon),
                      SizedBox(
                        width: context.screenWidth * 0.24,
                        child: Text("Weight", style: AppTextTheme().lightText.copyWith(fontSize: 16)),
                      ),

                      Expanded(
                        child: CustomTextfieldWidget(hintText: "0''", keyboardType: TextInputType.number),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppTheme.horizontalPadding),
              child: CustomButtonWidget(
                title: "Save",
                onPressed: () {
                  context.popPage();
                },
              ),
            ),
            30.h,
          ],
        ),
      ),
    );
  }

  void openSettingBottomSheet() {
    Helpers.openBottomSheet(
      context: context,
      child: StatefulBuilder(
        builder: (context, setState) {
          return SizedBox(
            height: context.screenHeight * 0.80,
            // decoration: BoxDecoration(
            //   color: Colors.white
            // ),
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.horizontalPadding),
              children: [
                Row(
                  spacing: 10,
                  children: [
                    GestureDetector(
                      onTap: () {
                        context.popPage();
                      },
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: AppColorTheme().whiteShade,
                        child: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
                      ),
                    ),
                    Text("Settings", style: AppTextTheme().subHeadingText.copyWith(fontWeight: AppFontWeight.semiBold, fontSize: 20)),
                  ],
                ),
                20.h,
                DashedLine(),
                20.h,

                // Vehicle
                Text("Vehicle", style: AppTextTheme().lightText.copyWith(color: AppColorTheme().secondary)),
                20.h,
                ListTile(
                  onTap: () {
                    openTruckSetting();
                  },
                  leading: SvgPicture.asset(AppIcons.localShippingIcon),
                  title: Text("My truck", style: AppTextTheme().lightText.copyWith(fontSize: 16)),
                  trailing: const Icon(Icons.play_arrow, color: Colors.black, size: 22),
                  contentPadding: EdgeInsets.zero,
                ),

                // Truck info list
                ...List.generate(
                  truckInfo.length,
                  (index) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: 20.w,
                    title: Text(truckInfo.entries.elementAt(index).key, style: AppTextTheme().lightText),
                    visualDensity: const VisualDensity(vertical: -4.0),
                    trailing: Text(
                      truckInfo.entries.elementAt(index).value,
                      style: AppTextTheme().lightText.copyWith(color: AppColorTheme().secondary),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),

                20.h,

                // Restrictions
                Text("Restrictions", style: AppTextTheme().lightText.copyWith(color: AppColorTheme().secondary)),
                20.h,
                ...List.generate(
                  routeRestriction.length,
                  (index) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: SvgPicture.asset(_setRestrictionIcon(routeRestriction.entries.elementAt(index).key)),
                    title: Text(routeRestriction.entries.elementAt(index).key, style: AppTextTheme().lightText),
                    visualDensity: const VisualDensity(vertical: -4.0),
                    trailing: Transform.scale(
                      scale: 0.6,
                      child: Switch.adaptive(
                        value: routeRestriction.entries.elementAt(index).value,
                        onChanged: (v) {
                          setState(() {
                            routeRestriction.update(routeRestriction.entries.elementAt(index).key, (c) => v);
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void openRouteDialogSheet() {
    Helpers.openBottomSheet(
      context: context,
      child: StatefulBuilder(
        builder: (context, setState) {
          return SizedBox(
            height: context.screenHeight * 0.8,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.all(AppTheme.horizontalPadding),
                    children: [
                      Row(
                        spacing: 10,
                        children: [
                          GestureDetector(
                            onTap: () {
                              context.popPage();
                            },
                            child: CircleAvatar(
                              radius: 25,
                              backgroundColor: AppColorTheme().whiteShade,
                              child: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                style: AppTextTheme().subHeadingText.copyWith(fontSize: 20),
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "2h 11m",
                                      style: TextStyle(color: AppColorTheme().primary),
                                    ),
                                    TextSpan(text: " (122 mi)"),
                                  ],
                                ),
                              ),
                              Text("via I-20E", style: AppTextTheme().lightText.copyWith(color: AppColorTheme().secondary)),
                            ],
                          ),
                        ],
                      ),
                      20.h,
                      DashedLine(),
                      20.h,
                      Row(
                        spacing: 10,
                        children: [
                          Column(
                            spacing: 5,
                            children: [
                              Icon(Icons.circle_outlined, size: 18),
                              SizedBox(
                                height: 30, // match with textfield height + spacing
                                child: CustomPaint(painter: DottedLinePainter()),
                              ),

                              Icon(Icons.location_on, size: 24),
                            ],
                          ),
                          Expanded(
                            child: Column(
                              spacing: 10,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("Times Square, New York, NY, USA", style: AppTextTheme().bodyText.copyWith(fontSize: 16), maxLines: 2),
                                Row(
                                  children: [
                                    Icon(Icons.u_turn_right),
                                    Text("20 min (25 mi)", style: AppTextTheme().lightText.copyWith(color: AppColorTheme().primary)),
                                  ],
                                ),
                                Text("Centre St, Scranton, PA", style: AppTextTheme().bodyText.copyWith(fontSize: 16), maxLines: 2),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(AppTheme.horizontalPadding),
                  child: CustomButtonWidget(
                    title: "Start navigation",
                    onPressed: () {
                      //  openNavigationDialogSheet();
                      context.popPage();

                      startNavigation();
                    },
                    icon: Icon(Icons.double_arrow, color: Colors.white, size: 18),
                    isRightSide: true,
                  ),
                ),
                20.h,
              ],
            ),
          );
        },
      ),
    );
  }

  // void openNavigationDialogSheet(){
  //   Helpers.openBottomSheet(context: context, child: DraggableScrollableSheet(
  //     expand: false,
  //     initialChildSize: 0.9,
  //     minChildSize: 0.2,
  //     maxChildSize: 0.9,
  //     builder: (context, scrollController) {
  //       return Container(
  //         padding: EdgeInsets.all(16),
  //         decoration: BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //         ),
  //         child: ListView(
  //           controller: scrollController,
  //           children: [

  //             Text("Draggable Sheet", style: TextStyle(fontSize: 18)),
  //             ...List.generate(20, (i) => ListTile(title: Text("Item $i"))),
  //           ],
  //         ),
  //       );
  //     },
  //   ));
  // }

  // void createTripBottomModalSheet(){
  //   Helpers.openBottomSheet(context: context, child: StatefulBuilder(
  //     builder: (context, setState) {
  //       return SizedBox(
  //         height: context.screenHeight * 0.8,
  //         child: ListView(
  //           padding: EdgeInsets.symmetric(horizontal: AppTheme.horizontalPadding),
  //           children: [
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                       children: [
  //                         Text(
  //                           "Create a trip",
  //                           style: AppTextTheme().subHeadingText.copyWith(
  //                             fontWeight: AppFontWeight.semiBold,
  //                             fontSize: 20,
  //                           ),
  //                         ),

  //                         IconButton(
  //                           padding: EdgeInsets.zero,
  //                           visualDensity: VisualDensity(
  //                             horizontal: -4.0,
  //                             vertical: -4.0,
  //                           ),
  //                           onPressed: () {
  //                            context.popPage();
  //                           },
  //                           icon: Icon(Icons.close, color: Colors.black),
  //                         ),
  //                       ],
  //                     ),
  //                     20.h,
  //                     VerticalStepWithTextField(
  //                       focusNode: focusNode,
  //                       textControllers: textController,
  //                       removeFieldTap: () {
  //                         setState(() {
  //                           textController.removeLast();
  //                         });
  //                       },
  //                     ),
  //                     5.h,
  //                     TextButton(
  //                       style: ButtonStyle(
  //                         padding: WidgetStatePropertyAll(EdgeInsets.zero),
  //                         visualDensity: VisualDensity(
  //                           horizontal: -4.0,
  //                           vertical: -4.0,
  //                         ),
  //                       ),
  //                       onPressed: () {
  //                         setState(() {
  //                           textController.add(TextEditingController());
  //                           focusNode.add(FocusNode());
  //                         });
  //                       },
  //                       child: Row(
  //                         spacing: 5,
  //                         children: [
  //                           Icon(Icons.add, size: 25),
  //                           Text(
  //                             "Add a stop",
  //                             style: AppTextTheme().bodyText.copyWith(
  //                               color: AppColorTheme().primary,
  //                               fontSize: 16,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                     20.h,
  //                     DashedLine(),
  //                     20.h,
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                       children: [
  //                         Text(
  //                           "Settings",
  //                           style: AppTextTheme().subHeadingText.copyWith(
  //                             fontSize: 16,
  //                           ),
  //                         ),
  //                         IconButton(
  //                           onPressed: () {
  //                             openSettingBottomSheet();
  //                           },
  //                           icon: SvgPicture.asset(AppIcons.settingIcon),
  //                           style: ButtonStyle(
  //                             padding: WidgetStatePropertyAll(EdgeInsets.zero),
  //                             visualDensity: VisualDensity(
  //                               horizontal: -4.0,
  //                               vertical: -4.0,
  //                             ),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                     Wrap(
  //                       spacing: 5,

  //                       children: List.generate(
  //                         settingChipsList.length,
  //                         (index) => Chip(
  //                           deleteIconColor: AppColorTheme().secondary,
  //                           onDeleted: () {
  //                             setState(() {
  //                               settingChipsList.removeAt(index);
  //                             });
  //                           },
  //                           deleteIconBoxConstraints: BoxConstraints(
  //                             maxHeight: 24,
  //                             maxWidth: 24,
  //                           ),
  //                           padding: EdgeInsets.symmetric(
  //                             vertical: 0,
  //                             horizontal: 3,
  //                           ),
  //                           backgroundColor: Color(0xffF4F6F8),
  //                           deleteIcon: Icon(Icons.cancel),

  //                           label: Text(settingChipsList[index]),
  //                           shape: RoundedRectangleBorder(
  //                             borderRadius: BorderRadius.circular(50),
  //                             side: BorderSide(color: Colors.transparent),
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                     20.h,
  //                     DashedLine(),
  //                     20.h,
  //                     Text(
  //                       "Availables routes",
  //                       style: AppTextTheme().subHeadingText.copyWith(fontSize: 16),
  //                     ),
  //                     ...List.generate(
  //                       3,
  //                       (index) => ListTile(
  //                         // minLeadingWidth: 20,
  //                         contentPadding: EdgeInsets.symmetric(vertical: 5),
  //                         leading: CircleAvatar(
  //                           radius: 25,
  //                           backgroundColor: Color(0xffF4F6F8),
  //                           child: SvgPicture.asset(AppIcons.truckIcon),
  //                         ),
  //                         title: Text(
  //                           "Via I-20E",
  //                           style: AppTextTheme().bodyText.copyWith(fontSize: 16),
  //                         ),
  //                         subtitle: index == 0
  //                             ? Row(
  //                                 spacing: 4,
  //                                 children: [
  //                                   Icon(
  //                                     Icons.warning_rounded,
  //                                     size: 16,
  //                                     color: Color(0xffFF4F5B),
  //                                   ),
  //                                   Text(
  //                                     "This route requires tolls",
  //                                     style: AppTextTheme().lightText.copyWith(
  //                                       color: AppColorTheme().secondary,
  //                                     ),
  //                                   ),
  //                                 ],
  //                               )
  //                             : null,
  //                         trailing: Row(
  //                           spacing: 5,
  //                           mainAxisSize: MainAxisSize.min,
  //                           children: [
  //                             Column(
  //                               mainAxisSize: MainAxisSize.min,
  //                               children: [
  //                                 Text(
  //                                   "2h 11m",
  //                                   style: AppTextTheme().lightText.copyWith(
  //                                     color: AppColorTheme().primary,
  //                                   ),
  //                                 ),
  //                                 Text(
  //                                   "145 mi",
  //                                   style: AppTextTheme().lightText.copyWith(
  //                                     color: AppColorTheme().secondary,
  //                                   ),
  //                                 ),
  //                               ],
  //                             ),
  //                             Icon(Icons.directions, color: Colors.black, size: 20),
  //                           ],
  //                         ),
  //                       ),
  //                     ),
  //                   ],

  //         ),
  //       );
  //     }
  //   ));
  // }

  void saveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColorTheme().primary.withValues(alpha: 0.2)),
              child: Icon(Icons.bookmark_outline),
            ),
            Text("Save this route ", style: AppTextTheme().headingText.copyWith(fontSize: 20)),
            Text(
              "Would you like to save this route for future use?",
              style: AppTextTheme().lightText.copyWith(color: AppColorTheme().secondary),
              textAlign: TextAlign.center,
            ),
            CustomButtonWidget(
              title: "Yes",
              onPressed: () {
                // context.popPage();
                // setState(() {
                //   isStartNav = false;
                //   isSetDirection = false;
                //   searchTextEditController.clear();
                // });
                context.pushReplacementPage(HomeView());
              },
            ),
            CustomButtonWidget(
              title: "No",
              onPressed: () {
                context.popPage();
              },
              textColor: Colors.black,
              bgColor: AppColorTheme().whiteShade,
            ),
          ],
        ),
      ),
    );
  }

  void startNavigation() {
    setState(() {
      isStartNav = true;
    });
    context.read<MapCubit>().startNavigation();
  }

  void cancelNavigation() {
    setState(() {
      isStartNav = false;
    });
    openRouteDialogSheet();
  }

  bool isSetDirection = false;
  bool isStartNav = false;
  _setDirectionIcon(int index) {
    switch (index) {
      case 0:
        return Icons.turn_slight_left;
      case 1:
        return Icons.straight;
      case 2:
        return Icons.turn_left;
      case 3:
        return Icons.turn_right;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(76),

        child: AppBar(
          leadingWidth: context.screenWidth * 0.45,
          leading: Row(mainAxisSize: MainAxisSize.min, children: [20.w, Image.asset(AppIcons.logo, width: 126, height: 22)]),
          actions: [
            Container(
              height: 44,
              width: 44,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Color(0xFFEBEEF2), width: 1), // rgba(235, 238, 242, 1)
                borderRadius: BorderRadius.circular(8), // Optional
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.04), // rgba(0, 0, 0, 0.04)
                    blurRadius: 6, // Spread of the blur
                    offset: Offset(0, 2), // X=0, Y=2
                  ),
                ],
              ),
              child: SvgPicture.asset(AppIcons.menuIcon, width: 20, height: 20),
            ),
            20.w,
          ],
          bottom: PreferredSize(preferredSize: Size.fromHeight(0.8), child: Divider()),
        ),
      ),
      body: Stack(
        // alignment: Alignment.center,
        children: !isStartNav
            ? [
                // Background content
                MapView(),
                if (changeMapScheme)
                  Align(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      width: 271,

                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        spacing: 20,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(mapSchemes.length, (index) {
                          final item = mapSchemes[index];
                          return _styleButton(item.label, item.scheme, item.icon, index);
                        }),
                      ),
                    ),
                  ),
                Positioned(
                  right: 10,
                  bottom: context.screenHeight * 0.25,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 10,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            changeMapScheme = !changeMapScheme;
                          });
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),

                          child: Container(
                            width: 48,
                            height: 48,
                            padding: EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x0A000000), // same as #0000000A
                                  offset: Offset(0, 2), // x=0, y=2
                                  blurRadius: 6, // blur radius
                                  spreadRadius: 0, // spread
                                ),
                              ],
                              shape: BoxShape.circle,
                              color: changeMapScheme ? AppColorTheme().primary.withValues(alpha: 0.2) : Colors.white,
                            ),
                            child: SvgPicture.asset(
                              AppIcons.layerBoxIcon,
                              colorFilter: changeMapScheme ? ColorFilter.mode(AppColorTheme().primary, BlendMode.srcIn) : null,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 48,
                        // height: 200,
                        // padding: EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(50), bottom: Radius.circular(50)),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x0A000000), // same as #0000000A
                              offset: Offset(0, 2), // x=0, y=2
                              blurRadius: 6, // blur radius
                              spreadRadius: 0, // spread
                            ),
                          ],

                          color: Colors.white,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                Point2D center = Point2D(context.screenWidth / 2, context.screenHeight / 2);
                                context.read<MapCubit>().mapZoomIn(center);
                              },
                              icon: SvgPicture.asset(AppIcons.zoomInIcon),
                            ),
                            IconButton(
                              onPressed: () {
                                Point2D center = Point2D(context.screenWidth / 2, context.screenHeight / 2);
                                context.read<MapCubit>().mapZoomOut(center);
                                ;
                              },
                              icon: SvgPicture.asset(AppIcons.zoomOutIcon),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        padding: EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x0A000000), // same as #0000000A
                              offset: Offset(0, 2), // x=0, y=2
                              blurRadius: 6, // blur radius
                              spreadRadius: 0, // spread
                            ),
                          ],
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: SvgPicture.asset(AppIcons.navigationIconGreen, colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn)),
                      ),
                    ],
                  ),
                ),

                Container(
                  margin: EdgeInsets.only(top: 10),
                  height: 40,
                  // width: double.infinity,
                  child: ListView.separated(
                    itemCount: stationList.length,
                    padding: EdgeInsets.symmetric(horizontal: AppTheme.horizontalPadding),
                    separatorBuilder: (context, index) => 5.w,
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () {
                        _hereMapController?.mapScene.enableFeatures({MapFeatures.lowSpeedZones: MapFeatureModes.lowSpeedZonesAll});
                        _truckGuidanceExample = TruckGuidanceExample(_showDialog, _hereMapController!);
                      },
                      child: Container(
                        // width: 100,
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: const Color.fromRGBO(235, 238, 242, 1), // border color
                            width: 1, // border width
                          ),
                          borderRadius: BorderRadius.circular(50), // optional rounded corners
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.04), // shadow color
                              offset: Offset(0, 2), // x=0, y=2 (downwards)
                              blurRadius: 6, // soft shadow
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          spacing: 10,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: index % 2 == 0 ? Color(0xff4676F6) : Color(0xffFFC300),
                              child: Text(stationList[index].splitMapJoin('')[0], style: AppTextTheme().headingText.copyWith(fontSize: 16)),
                            ),
                            Text(stationList[index], style: AppTextTheme().bodyText),
                          ],
                        ),
                      ),
                    ),
                    scrollDirection: Axis.horizontal,
                  ),
                  // width: double.infinity,
                ),

                CustomDragableWidget(
                  childrens: isSetDirection
                      ? [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Create a trip", style: AppTextTheme().subHeadingText.copyWith(fontWeight: AppFontWeight.semiBold, fontSize: 20)),

                              IconButton(
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity(horizontal: -4.0, vertical: -4.0),
                                onPressed: () {
                                  setState(() {
                                    isSetDirection = false;
                                  });
                                  context.read<MapCubit>().clearRoute();
                                },
                                icon: Icon(Icons.close, color: Colors.black),
                              ),
                            ],
                          ),
                          20.h,
                          VerticalStepWithTextField(
                            focusNode: focusNode,
                            textControllers: textController,
                            removeFieldTap: () {
                              setState(() {
                                textController.removeLast();
                              });
                            },
                          ),
                          5.h,
                          TextButton(
                            style: ButtonStyle(
                              padding: WidgetStatePropertyAll(EdgeInsets.zero),
                              visualDensity: VisualDensity(horizontal: -4.0, vertical: -4.0),
                            ),
                            onPressed: () {
                              setState(() {
                                textController.add(TextEditingController());
                                focusNode.add(FocusNode());
                              });
                            },
                            child: Row(
                              spacing: 5,
                              children: [
                                Icon(Icons.add, size: 25),
                                Text("Add a stop", style: AppTextTheme().bodyText.copyWith(color: AppColorTheme().primary, fontSize: 16)),
                              ],
                            ),
                          ),
                          20.h,
                          DashedLine(),
                          20.h,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Settings", style: AppTextTheme().subHeadingText.copyWith(fontSize: 16)),
                              IconButton(
                                onPressed: () {
                                  openSettingBottomSheet();
                                },
                                icon: SvgPicture.asset(AppIcons.settingIcon),
                                style: ButtonStyle(
                                  padding: WidgetStatePropertyAll(EdgeInsets.zero),
                                  visualDensity: VisualDensity(horizontal: -4.0, vertical: -4.0),
                                ),
                              ),
                            ],
                          ),
                          Wrap(
                            spacing: 5,

                            children: List.generate(
                              settingChipsList.length,
                              (index) => Chip(
                                deleteIconColor: AppColorTheme().secondary,
                                onDeleted: () {
                                  setState(() {
                                    settingChipsList.removeAt(index);
                                  });
                                },
                                deleteIconBoxConstraints: BoxConstraints(maxHeight: 24, maxWidth: 24),
                                padding: EdgeInsets.symmetric(vertical: 0, horizontal: 3),
                                backgroundColor: Color(0xffF4F6F8),
                                deleteIcon: Icon(Icons.cancel),

                                label: Text(settingChipsList[index]),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                  side: BorderSide(color: Colors.transparent),
                                ),
                              ),
                            ),
                          ),
                          20.h,
                          DashedLine(),
                          20.h,
                          Text("Availables routes", style: AppTextTheme().subHeadingText.copyWith(fontSize: 16)),
                          BlocBuilder<MapCubit, MapState>(
                            builder: (context, state) {
                              return Column(
                                children: List.generate(
                                  state.availableDestinationRoutes?.length ?? 0,
                                  (index) => ListTile(
                                    // minLeadingWidth: 20,
                                    onTap: () {
                                      openRouteDialogSheet();
                                      // if (state.availableDestinationRoutes?[index] != null) {
                                      //   _truckGuidanceExample?.selectRouteAndDrawPolyLines(state.availableDestinationRoutes![index]);
                                      // }
                                    },
                                    contentPadding: EdgeInsets.symmetric(vertical: 5),
                                    leading: CircleAvatar(
                                      radius: 25,
                                      backgroundColor: Color(0xffF4F6F8),
                                      child: SvgPicture.asset(AppIcons.truckIcon),
                                    ),
                                    title: Text(
                                      // "Via I-20E",
                                      "Route ${index + 1}",
                                      style: AppTextTheme().bodyText.copyWith(fontSize: 16),
                                    ),
                                    subtitle: (state.availableDestinationRoutes?[index].hasTolls ?? false)
                                        ? Row(
                                            spacing: 4,
                                            children: [
                                              Icon(Icons.warning_rounded, size: 16, color: Color(0xffFF4F5B)),
                                              Expanded(
                                                child: Text(
                                                  "This route requires tolls",
                                                  style: AppTextTheme().lightText.copyWith(color: AppColorTheme().secondary),
                                                ),
                                              ),
                                            ],
                                          )
                                        : null,
                                    trailing: Row(
                                      spacing: 5,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              state.availableDestinationRoutes?[index].formattedDuration ?? '',
                                              // "2h 11m",
                                              style: AppTextTheme().lightText.copyWith(color: AppColorTheme().primary),
                                            ),
                                            Text(
                                              state.availableDestinationRoutes?[index].distanceInMiles ?? '',
                                              //  "145 mi",
                                              style: AppTextTheme().lightText.copyWith(color: AppColorTheme().secondary),
                                            ),
                                          ],
                                        ),
                                        Icon(Icons.directions, color: Colors.black, size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ]
                      : [
                          CustomTextfieldWidget(
                            focusNode: searchFieldFocusNode,
                            onTapOutside: (e) {},
                            onChanged: (text) {
                              setState(() {});
                              Future.delayed(Duration(milliseconds: 400), () {
                                if (context.mounted) {
                                  context.read<MapCubit>().searchLocation(text, TruckGuidanceExample.myStartCoordinadtes);
                                }
                              });
                            },

                            prefixIcon: SvgPicture.asset(AppIcons.searchIcon),
                            hintText: "Find a destination...",
                            controller: searchTextEditController,
                            suffixIcon: searchFieldFocusNode.hasFocus
                                ? searchTextEditController.text.isEmpty
                                      ? SvgPicture.asset(AppIcons.mapSearchIcon)
                                      : GestureDetector(
                                          onTap: () {
                                            searchTextEditController.clear();
                                            setState(() {});
                                          },
                                          child: Icon(Icons.close),
                                        )
                                : null,
                          ),
                          15.h,
                          CustomButtonWidget(
                            title: "Get Direction",
                            onPressed: () {
                              if (searchTextEditController.text.isNotEmpty) {
                                setState(() {
                                  isSetDirection = true;
                                });
                                context.read<MapCubit>().setRoute();
                              }
                            },
                            icon: Icon(Icons.directions, color: Colors.white),
                          ),
                          15.h,
                          DashedLine(color: Color(0xffEBEEF2)),
                          if (!searchFieldFocusNode.hasFocus) ...[
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundColor: AppColorTheme().primary.withValues(alpha: 0.2),
                                child: SvgPicture.asset(AppIcons.navigationIconGreen),
                              ),
                              title: Text("210 Riverside Drive", style: AppTextTheme().bodyText.copyWith(color: Colors.black, fontSize: 16)),
                              subtitle: Text("New York, NY 10025", style: AppTextTheme().lightText.copyWith(color: AppColorTheme().secondary)),
                            ),
                            15.h,
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(backgroundColor: Colors.transparent, radius: 25, child: SvgPicture.asset(AppIcons.weatherIcon)),
                              title: Text("24°C", style: AppTextTheme().bodyText.copyWith(color: Colors.black, fontSize: 16)),
                              subtitle: Row(
                                spacing: 4,
                                children: [
                                  Icon(Icons.warning_rounded, size: 16, color: Color(0xffFF4F5B)),
                                  Expanded(
                                    child: Text(
                                      "The light rain next 2 hours",
                                      style: AppTextTheme().lightText.copyWith(color: AppColorTheme().secondary),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Icon(Icons.arrow_forward_ios, color: Colors.black, size: 15, weight: 30),
                            ),
                            15.h,
                            DashedLine(color: Color(0xffEBEEF2)),
                            15.h,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Nearby places", style: AppTextTheme().headingText.copyWith(fontSize: 16)),
                                TextButton(
                                  style: ButtonStyle(
                                    visualDensity: VisualDensity(vertical: -4.0, horizontal: -4.0),
                                    padding: WidgetStatePropertyAll(EdgeInsets.zero),
                                  ),
                                  onPressed: () {
                                    openDialog();
                                  },
                                  child: Text("More", style: AppTextTheme().bodyText.copyWith(color: AppColorTheme().primary)),
                                ),
                              ],
                            ),
                            15.h,
                            ...List.generate(places.length, (index) {
                              final place = places[index];
                              return PlaceDisplayWidget(place: place);
                            }),
                            DashedLine(color: Color(0xffEBEEF2)),
                            15.h,
                            Text("Quick Actions", style: AppTextTheme().headingText.copyWith(fontSize: 16)),
                            15.h,
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 7, horizontal: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Color(0xFFEBEEF2), width: 1),
                              ),
                              child: Row(
                                spacing: 5,
                                children: [
                                  Icon(Icons.bookmark_sharp),
                                  Expanded(child: Text("Saved & recent places", style: AppTextTheme().bodyText.copyWith(fontSize: 16))),
                                  Icon(Icons.arrow_forward_ios, color: Colors.black, size: 15, weight: 30),
                                ],
                              ),
                            ),
                            20.h,
                          ],
                          if (searchFieldFocusNode.hasFocus && searchTextEditController.text.isEmpty) ...[
                            15.h,

                            CustomTabBarWidget(options: locationOpt, tabController: _tabController),
                            15.h,
                            SizedBox(
                              height: context.screenHeight * 0.6,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  ListView(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    physics: NeverScrollableScrollPhysics(),
                                    children: [
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: CircleAvatar(
                                          radius: 25,
                                          backgroundColor: AppColorTheme().primary.withValues(alpha: 0.2),
                                          child: SvgPicture.asset(AppIcons.navigationIconGreen),
                                        ),
                                        title: Text("My location", style: AppTextTheme().bodyText.copyWith(fontSize: 16)),
                                      ),
                                      ...List.generate(
                                        4,
                                        (index) => ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: CircleAvatar(
                                            radius: 25,
                                            backgroundColor: Color(0xffF4F6F8),
                                            child: SvgPicture.asset(AppIcons.frameIcon),
                                          ),
                                          title: Text("1600 Amphitheatre Parkway", style: AppTextTheme().bodyText.copyWith(fontSize: 16)),
                                          subtitle: Text(
                                            "Manhattan, New York, NY, USA",
                                            style: AppTextTheme().lightText.copyWith(color: AppColorTheme().secondary),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  ListView.builder(
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) => GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          searchTextEditController.text = places[index].address;
                                          place = places[index];
                                        });
                                      },
                                      child: PlaceDisplayWidget(place: places[index], isSaved: true),
                                    ),
                                    itemCount: places.length,
                                  ),
                                  ListView.builder(
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) => PlaceDisplayWidget(place: terminals[index], isSaved: true),
                                    itemCount: terminals.length,
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (searchFieldFocusNode.hasFocus && searchTextEditController.text.isNotEmpty) ...[
                            BlocBuilder<MapCubit, MapState>(
                              buildWhen: (previous, current) {
                                return previous.suggestionDestination != current.suggestionDestination;
                              },
                              builder: (context, state) {
                                return state.suggestionDestination != null && state.suggestionDestination!.isNotEmpty
                                    ? ListView.separated(
                                        itemBuilder: (context, index) {
                                          final Suggestion item = state.suggestionDestination![index];
                                          return ListTile(
                                            onTap: () {
                                              searchTextEditController.text = item.title;
                                              context.read<MapCubit>().setDestinationCoordinate(item.place!.geoCoordinates!);
                                            },
                                            contentPadding: EdgeInsets.zero,
                                            leading: CircleAvatar(
                                              radius: 25,
                                              backgroundColor: AppColorTheme().primary.withValues(alpha: 0.2),
                                              child: SvgPicture.asset(AppIcons.navigationIconGreen),
                                            ),
                                            title: Text(
                                              item.title,
                                              maxLines: 1,
                                              style: AppTextTheme().bodyText.copyWith(color: Colors.black, fontSize: 16),
                                            ),
                                            subtitle: Text(
                                              "${item.place?.address.addressText}",
                                              maxLines: 2,
                                              style: AppTextTheme().lightText.copyWith(color: AppColorTheme().secondary),
                                            ),
                                          );
                                        },
                                        separatorBuilder: (context, index) => Divider(),
                                        itemCount: state.suggestionDestination!.length,
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                      )
                                    : SizedBox(
                                        height: context.screenHeight * 0.45,
                                        child: Center(child: Text("No result found!")),
                                      );
                              },
                            ),
                          ],

                          if (searchFieldFocusNode.hasFocus && searchTextEditController.text.isNotEmpty && place != null) ...[
                            15.h,
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(image: AssetImage(place!.icon)),
                                ),
                              ),
                              title: Text(place!.title, style: AppTextTheme().headingText.copyWith(fontSize: 20)),
                              subtitle: Row(
                                spacing: 3,
                                children: [
                                  // ...List.generate(
                                  //   5,
                                  //   (index) =>
                                  //       SvgPicture.asset(AppIcons.ratingIcon),
                                  // ),
                                  CustomRatingIndicator(rating: 5.0),
                                  Text(place!.rating.toString(), style: AppTextTheme().lightText.copyWith(color: Color(0xffFF8800))),
                                  Text(
                                    "(${place!.reviewCount})  • ${place!.storeType} • ${place!.distance} mi",
                                    style: AppTextTheme().lightText.copyWith(color: AppColorTheme().secondary),
                                  ),
                                ],
                              ),
                            ),
                            10.h,
                            Row(
                              spacing: 10,
                              children: [
                                Expanded(
                                  child: Container(
                                    alignment: Alignment.center,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.horizontal(left: Radius.circular(50), right: Radius.circular(50)),
                                      border: Border.all(color: Color(0xffEBEEF2)),
                                    ),
                                    child: Row(
                                      spacing: 5,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.bookmark_border_outlined, color: Colors.black, size: 20),
                                        Text("Save", style: AppTextTheme().bodyText.copyWith(fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    alignment: Alignment.center,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.horizontal(left: Radius.circular(50), right: Radius.circular(50)),
                                      border: Border.all(color: Color(0xffEBEEF2)),
                                    ),
                                    child: Row(
                                      spacing: 5,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.phone_outlined, color: Colors.black, size: 20),
                                        Text("Save", style: AppTextTheme().bodyText.copyWith(fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            20.h,
                            DashedLine(),
                            20.h,
                            ListTile(
                              leading: Icon(Icons.location_on_outlined, color: Colors.black),
                              horizontalTitleGap: 5,
                              title: Text(place!.address, style: AppTextTheme().lightText.copyWith(fontSize: 16)),
                            ),
                            ListTile(
                              leading: Icon(Icons.schedule, color: Colors.black),
                              horizontalTitleGap: 5,
                              title: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: place!.shopStatus == "Open" ? "Opened" : "Closed",
                                      style: AppTextTheme().lightText.copyWith(
                                        fontSize: 16,
                                        color: place!.shopStatus == "Open" ? AppColorTheme().primary : Colors.red,
                                      ),
                                    ),
                                    TextSpan(
                                      text: "  •  ", // example extra text
                                      style: AppTextTheme().lightText.copyWith(fontSize: 16, color: AppColorTheme().secondary),
                                    ),
                                    TextSpan(text: place!.shopStatus != "Open" ? "Opens at ${place!.time}" : "Closes at ${place!.time}"),
                                  ],
                                ),
                              ),
                            ),
                            ListTile(
                              leading: Icon(Icons.phone_outlined, color: Colors.black),
                              horizontalTitleGap: 5,
                              title: Text("(406) 555-0120 ", style: AppTextTheme().lightText.copyWith(fontSize: 16)),
                            ),
                            ListTile(
                              leading: Icon(Icons.language, color: Colors.black),
                              horizontalTitleGap: 5,
                              title: Text("https://www.elizabeth-restaurant.com", style: AppTextTheme().lightText.copyWith(fontSize: 16)),
                            ),
                            10.h,
                            DashedLine(),
                            15.h,
                            Wrap(
                              spacing: 8, // space between chips
                              runSpacing: 8, // space between lines
                              children: ["Parking", "ATM", "WI-FI"].map((e) {
                                return Chip(
                                  padding: EdgeInsets.zero,
                                  labelPadding: const EdgeInsets.only(right: 8),
                                  avatar: Icon(Icons.check_circle_outline, color: Colors.green, size: 24),
                                  label: Text(e, style: TextStyle(fontSize: 14)),
                                  backgroundColor: const Color(0xffF4F6F8),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(color: Colors.transparent),
                                    borderRadius: BorderRadius.circular(50), // pill shape
                                  ),
                                );
                              }).toList(),
                            ),
                            15.h,
                            DashedLine(),
                            20.h,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Q&As", style: AppTextTheme().headingText.copyWith(fontSize: 16)),
                                TextButton(
                                  style: ButtonStyle(
                                    padding: WidgetStatePropertyAll(EdgeInsets.zero),
                                    visualDensity: VisualDensity(horizontal: -4.0, vertical: -4.0),
                                  ),
                                  onPressed: () {},
                                  child: Text("More", style: AppTextTheme().headingText.copyWith(fontSize: 16, color: AppColorTheme().primary)),
                                ),
                              ],
                            ),
                            20.h,
                            ListView.separated(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) => Container(
                                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                height: 132,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Color(0xffEBEEF2)),
                                ),
                                child: Row(
                                  spacing: 10,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.help),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("Does Walmart allow overnight truck parking?", style: AppTextTheme().bodyText.copyWith(fontSize: 16)),
                                          Text(
                                            "Some locations do, but always check with the store first.",
                                            style: AppTextTheme().lightText.copyWith(color: AppColorTheme().secondary),
                                          ),
                                          Row(
                                            spacing: 8,
                                            children: [
                                              Text("View 7 replies", style: AppTextTheme().bodyText.copyWith(color: AppColorTheme().primary)),
                                              Icon(Icons.arrow_forward_ios, size: 15),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              separatorBuilder: (context, index) => 5.h,
                              itemCount: 2,
                            ),
                            20.h,
                            Row(
                              spacing: 5,
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundImage: NetworkImage(
                                    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?fm=jpg&q=60&w=3000&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8dXNlciUyMHByb2ZpbGV8ZW58MHx8MHx8fDA%3D',
                                  ),
                                ),
                                Expanded(
                                  child: CustomTextfieldWidget(
                                    hintText: "Ask the question...",
                                    suffixIcon: CircleAvatar(backgroundColor: AppColorTheme().primary, child: Icon(Icons.arrow_upward, size: 18)),
                                  ),
                                ),
                              ],
                            ),
                            20.h,
                            DashedLine(),
                            20.h,
                            Text(
                              "How was your experience here?",
                              style: AppTextTheme().bodyText.copyWith(fontSize: 16, fontWeight: AppFontWeight.semiBold),
                            ),
                            20.h,
                            RatingBar.builder(
                              itemPadding: EdgeInsets.all(3),
                              unratedColor: Color(0xffEBEEF2),
                              itemBuilder: (context, index) => SvgPicture.asset(AppIcons.ratingIcon),
                              onRatingUpdate: (rating) {},
                            ),
                          ],
                        ],
                ),
              ]
            : [
                MapView(),
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 150,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white, // background
                      borderRadius: BorderRadius.circular(20), // border-radius: 20px
                      border: Border.all(
                        color: const Color(0xFFEBEEF2), // #EBEEF2
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(136, 139, 161, 0.18), // rgba(136,139,161,0.18)
                          offset: const Offset(4, 4), // x:4px, y:4px
                          blurRadius: 24, // blur
                          spreadRadius: -4, // -4px spread
                        ),
                      ],
                    ),
                    child: Column(
                      spacing: 10,
                      children: [
                        Row(
                          spacing: 10,
                          children: [
                            CircleAvatar(radius: 20, backgroundColor: AppColorTheme().primary, child: Icon(Icons.turn_right)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Turn right in 500 m", style: AppTextTheme().subHeadingText2.copyWith(fontSize: 16)),
                                  Text("123 Industrial Blvd, CHI", style: AppTextTheme().lightText.copyWith(color: AppColorTheme().secondary)),
                                ],
                              ),
                            ),
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColorTheme().whiteShade,
                              child: Icon(Icons.volume_off_outlined, color: Colors.black),
                            ),
                          ],
                        ),
                        DashedLine(),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(color: AppColorTheme().whiteShade, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: List.generate(4, (index) {
                                return Expanded(child: Icon(_setDirectionIcon(index), color: AppColorTheme().secondary, size: 30, weight: 1.5));
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 200,
                  left: 20,
                  right: 20,
                  child: Row(
                    children: [
                      Container(
                        height: 80,
                        width: 160,
                        decoration: BoxDecoration(
                          color: Colors.white, // background
                          borderRadius: BorderRadius.circular(20), // border-radius: 20px
                          border: Border.all(
                            color: const Color(0xFFEBEEF2), // #EBEEF2
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromRGBO(136, 139, 161, 0.18), // rgba(136,139,161,0.18)
                              offset: const Offset(4, 4), // x:4px, y:4px
                              blurRadius: 24, // blur
                              spreadRadius: -4, // -4px spread
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: double.infinity,
                                margin: EdgeInsets.all(5),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.black, width: 2),
                                ),
                                child: Text("50", style: AppTextTheme().subHeadingText.copyWith(fontSize: 28)),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: double.infinity,
                                padding: EdgeInsets.all(5),

                                alignment: Alignment.center,

                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("5", style: AppTextTheme().subHeadingText.copyWith(fontSize: 28)),
                                    Text("mph"),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                CustomDragableWidget(
                  initialSize: 0.24,

                  bottomWidget: Padding(
                    padding: EdgeInsets.all(20),
                    child: CustomButtonWidget(
                      bgColor: AppColorTheme().whiteShade,
                      textColor: Colors.black,
                      icon: Icon(Icons.double_arrow, color: Colors.black, size: 18),
                      isRightSide: true,

                      title: "Finish Trip",
                      onPressed: () {
                        context.read<MapCubit>().startNavigation();

                        saveDialog();
                      },
                    ),
                  ),
                  childrens: [
                    Row(
                      spacing: 10,
                      children: [
                        GestureDetector(
                          onTap: () {
                            cancelNavigation();
                          },
                          child: CircleAvatar(
                            radius: 25,
                            backgroundColor: AppColorTheme().whiteShade,
                            child: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              style: AppTextTheme().subHeadingText.copyWith(fontSize: 20),
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: "2h 11m",
                                    style: TextStyle(color: AppColorTheme().primary),
                                  ),
                                  TextSpan(text: " (122 mi 2:10 pm)", style: AppTextTheme().bodyText.copyWith(fontSize: 16)),
                                ],
                              ),
                            ),
                            Text("via I-20E", style: AppTextTheme().lightText.copyWith(color: AppColorTheme().secondary)),
                          ],
                        ),
                      ],
                    ),
                    20.h,
                    DashedLine(),
                    20.h,
                    Row(
                      spacing: 10,
                      children: [
                        Icon(Icons.location_on),
                        Expanded(
                          child: Text(
                            "Times Square, New York, NY, USA",
                            style: AppTextTheme().bodyText.copyWith(fontWeight: AppFontWeight.semiBold, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    20.h,
                    CustomAccordionWidget(
                      title: "Along 8th Ave toward W 42nd St",
                      child: Padding(
                        padding: const EdgeInsets.only(left: 40),
                        child: Column(
                          spacing: 10,
                          children: [
                            10.h,
                            Row(
                              spacing: 10,
                              children: [
                                Text("20 min (25 mi)", style: AppTextTheme().bodyText.copyWith(color: AppColorTheme().secondary)),
                                Expanded(child: Divider()),
                              ],
                            ),
                            Row(
                              spacing: 10,
                              children: [
                                Icon(Icons.straight, color: AppColorTheme().secondary),
                                Expanded(child: Text("Head west on W 42nd St", style: AppTextTheme().lightText.copyWith(fontSize: 16))),
                              ],
                            ),
                            Row(
                              spacing: 10,
                              children: [
                                24.w,
                                Text("5 mi", style: AppTextTheme().bodyText.copyWith(color: AppColorTheme().secondary)),
                                Expanded(child: Divider()),
                              ],
                            ),
                            Row(
                              spacing: 10,
                              children: [
                                Icon(Icons.turn_left, color: AppColorTheme().secondary),
                                Expanded(child: Text("Turn left onto 9th Ave", style: AppTextTheme().lightText.copyWith(fontSize: 16))),
                              ],
                            ),
                            Row(
                              spacing: 10,
                              children: [
                                24.w,
                                Text("20 mi", style: AppTextTheme().bodyText.copyWith(color: AppColorTheme().secondary)),
                                Expanded(child: Divider()),
                              ],
                            ),
                            Row(
                              spacing: 10,
                              children: [
                                Icon(Icons.turn_sharp_right, color: AppColorTheme().secondary),
                                Expanded(
                                  child: Text("Keep right to merge onto Lincoln Tunnel", style: AppTextTheme().lightText.copyWith(fontSize: 16)),
                                ),
                              ],
                            ),
                            Row(
                              spacing: 10,
                              children: [
                                Icon(Icons.warning_rounded, color: Color(0xffFF4F5B)),
                                Expanded(
                                  child: Text(
                                    "Toll required at Lincoln Tunnel",
                                    style: AppTextTheme().bodyText.copyWith(color: AppColorTheme().secondary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    10.h,
                    CustomAccordionWidget(
                      title: "Continue via NJ-495 W → I-95 S",
                      child: Padding(
                        padding: const EdgeInsets.only(left: 40),
                        child: Column(
                          spacing: 10,
                          children: [
                            10.h,
                            Row(
                              spacing: 10,
                              children: [
                                Text("20 min (25 mi)", style: AppTextTheme().bodyText.copyWith(color: AppColorTheme().secondary)),
                                Expanded(child: Divider()),
                              ],
                            ),
                            Row(
                              spacing: 10,
                              children: [
                                Icon(Icons.straight, color: AppColorTheme().secondary),
                                Expanded(child: Text("Head west on W 42nd St", style: AppTextTheme().lightText.copyWith(fontSize: 16))),
                              ],
                            ),
                            Row(
                              spacing: 10,
                              children: [
                                24.w,
                                Text("5 mi", style: AppTextTheme().bodyText.copyWith(color: AppColorTheme().secondary)),
                                Expanded(child: Divider()),
                              ],
                            ),
                            Row(
                              spacing: 10,
                              children: [
                                Icon(Icons.turn_left, color: AppColorTheme().secondary),
                                Expanded(child: Text("Turn left onto 9th Ave", style: AppTextTheme().lightText.copyWith(fontSize: 16))),
                              ],
                            ),
                            Row(
                              spacing: 10,
                              children: [
                                24.w,
                                Text("20 mi", style: AppTextTheme().bodyText.copyWith(color: AppColorTheme().secondary)),
                                Expanded(child: Divider()),
                              ],
                            ),
                            Row(
                              spacing: 10,
                              children: [
                                Icon(Icons.turn_sharp_right, color: AppColorTheme().secondary),
                                Expanded(
                                  child: Text("Keep right to merge onto Lincoln Tunnel", style: AppTextTheme().lightText.copyWith(fontSize: 16)),
                                ),
                              ],
                            ),
                            Row(
                              spacing: 10,
                              children: [
                                Icon(Icons.warning_rounded, color: Color(0xffFF4F5B)),
                                Expanded(
                                  child: Text(
                                    "Toll required at Lincoln Tunnel",
                                    style: AppTextTheme().bodyText.copyWith(color: AppColorTheme().secondary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
      ),
    );
  }

  Widget _styleButton(String label, MapScheme scheme, String icon, int index) {
    bool isSelect = selectIndexMapView == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          context.read<MapCubit>().setMapViewScheme(scheme);
          setState(() {
            selectIndexMapView = index;
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 5,
          children: [
            Container(
              width: double.infinity,
              height: 69,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: isSelect ? Border.all(color: AppColorTheme().primary) : null,
                image: DecorationImage(image: AssetImage(icon), fit: BoxFit.cover),
              ),
            ),
            Text(label, style: AppTextTheme().bodyText.copyWith(color: isSelect ? AppColorTheme().primary : AppColorTheme().secondary)),
          ],
        ),
      ),
    );
    // return TextButton(
    // onPressed: () {
    //   _hereMapController?.mapScene.loadSceneForMapScheme(scheme,
    //       (MapError? error) {
    //     if (error != null) {
    //       print("Error loading scheme: $error");
    //     }
    //   });
    // },
    //   child: Text(label),
    // );
  }
}

class PlaceDisplayWidget extends StatelessWidget {
  final bool? isSaved;
  const PlaceDisplayWidget({super.key, required this.place, this.isSaved = false});

  final PlaceDataModel place;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Color(0xffF4F6F8),
          child: CircleAvatar(radius: 13, backgroundImage: AssetImage(place.icon)),
        ),
        Expanded(
          child: Column(
            spacing: 5,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(place.title, style: AppTextTheme().headingText.copyWith(fontSize: 16))),
                  Container(
                    width: 28,
                    height: 28,
                    // padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Color(0xFFEBEEF2), width: 1), // rgba(235, 238, 242, 1)
                      borderRadius: BorderRadius.circular(8), // Optional
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.04), // rgba(0, 0, 0, 0.04)
                          blurRadius: 6, // Spread of the blur
                          offset: Offset(0, 2), // X=0, Y=2
                        ),
                      ],
                    ),
                    child: Icon(
                      isSaved! ? Icons.bookmark : Icons.bookmark_border,
                      size: 17,
                      color: isSaved! ? AppColorTheme().primary : Colors.black,
                    ),
                  ),
                ],
              ),
              Row(
                spacing: 3,
                children: [
                  // Icon(Icons.star, color: Color(0xffFF8800), size: 15,),
                  SvgPicture.asset(AppIcons.ratingIcon),
                  Text(place.rating.toString(), style: AppTextTheme().bodyText.copyWith(color: Color(0xffFF8800))),
                  Text("(${place.reviewCount})", style: AppTextTheme().bodyText.copyWith(color: AppColorTheme().secondary)),
                  Text("  • ${place.storeType} • ${place.distance} mi", style: AppTextTheme().bodyText.copyWith(color: AppColorTheme().secondary)),
                ],
              ),
              Text(place.address, style: AppTextTheme().bodyText),
              Row(
                children: [
                  Text(
                    place.shopStatus == "Open" ? "Opened" : "Closed",
                    style: AppTextTheme().bodyText.copyWith(color: place.shopStatus == "Open" ? AppColorTheme().primary : Colors.redAccent),
                  ),
                  Text(
                    "  • ${place.shopStatus == "Open" ? "Closes" : "Opens"} at ${place.time} ",
                    style: AppTextTheme().bodyText.copyWith(color: AppColorTheme().secondary),
                  ),
                ],
              ),
              10.h,
            ],
          ),
        ),
      ],
    );
  }
}

class DashedLine extends StatelessWidget {
  final double height;
  final Color color;

  const DashedLine({super.key, this.height = 1, this.color = Colors.grey});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedLinePainter(color: Color(0xffEBEEF2), height: height),
      child: SizedBox(width: double.infinity, height: height),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final double height;
  final Color color;

  _DashedLinePainter({required this.color, required this.height});

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = height;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
