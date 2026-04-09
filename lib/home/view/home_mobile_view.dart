import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/navigation.dart';
import 'package:here_sdk/search.dart';
import 'package:ommo/custom_widget/custom_widget.dart';
import 'package:ommo/custom_widget/future_data_builder.dart';
import 'package:ommo/home/view/create_trip_view.dart';
import 'package:ommo/home/view/home_app_bar.dart';
import 'package:ommo/home/view/home_utils.dart';
import 'package:ommo/home/view/map_view.dart';
import 'package:ommo/home/view/trip_destination_widget.dart';
import 'package:ommo/home/view/truck_navigation/truck_navigation_static_details.dart';
import 'package:ommo/home/view/truck_navigation/truck_navigation_utils.dart';
import 'package:ommo/home/view/truck_specification/truck_specification_utils.dart';
import 'package:ommo/logic/cubit/truck_navigation/truck_navigation_cubit.dart';
import 'package:ommo/logic/cubit/truck_navigation/truck_navigation_state.dart';
import 'package:ommo/logic/cubit/truck_stops/truck_stop_cubit.dart';
import 'package:ommo/logic/cubit/truck_stops/truck_stops_state.dart';
import 'package:ommo/services/hive/recent_search/cubit/recent_search_cubit.dart';
import 'package:ommo/utils/extension/num_extension.dart';
import 'package:ommo/utils/extension/place_extension.dart';
import 'package:ommo/utils/extension/recent_search_model_extension.dart';
import 'package:ommo/utils/extension/route_extension.dart';
import 'package:ommo/utils/snacks/snackbar_utils.dart';
import 'package:ommo/utils/utils.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

import '../home.dart';

class HomeMobileView extends StatefulWidget {
  const HomeMobileView({super.key});

  @override
  State<HomeMobileView> createState() => _HomeMobileViewState();
}

class _HomeMobileViewState extends State<HomeMobileView>
    with SingleTickerProviderStateMixin {
  final TextEditingController searchTextEditController =
      TextEditingController();

  FocusNode searchFieldFocusNode = FocusNode();
  late final TabController _tabController;

  final List<TextEditingController> textController = [
    TextEditingController(text: "Your Location"),
  ];
  final List<FocusNode> focusNode = [FocusNode()];
  bool showMore = false;

  // changeMapScheme = false;
  ValueNotifier<bool> showChangeMapSchemeDialog = ValueNotifier(false);
  ValueNotifier<int> selectIndexMapView = ValueNotifier(0);
  // PlaceDataModel? place;
  int selectLocationOpt = 0;
  // bool isSetDirection = false;

  final DraggableScrollableController sheetScrollController =
      DraggableScrollableController();

  final DraggableScrollableController navigationSheetScrollController =
      DraggableScrollableController();

  final ValueNotifier<double> navigationSheetHeight = ValueNotifier(0.0);

  final ValueNotifier<Map<String, String>?> _selectedStation = ValueNotifier(
    null,
  );

  final ValueNotifier<List<String>> _selectedMapFeature = ValueNotifier([]);

  final List<Map<String, String>> mapFeature = [
    {'id': "1", "name": "Designated", 'icon': 'assets/images/Ellipse 6.png'},
    {'id': "2", 'name': "Traffic", 'icon': 'assets/images/sign.png'},
    {'id': "3", 'name': "No Trucks", 'icon': 'assets/images/images 1.png'},
    {'id': "4", 'name': "Max Height", 'icon': 'assets/images/images 1 (1).png'},
    {
      'id': "5",
      "name": "Max Length",
      'icon': 'assets/images/Ellipse 6 (1).png',
    },
    {'id': "6", "name": "Max Weight", 'icon': 'assets/images/images 1 (2).png'},
    {'id': "7", "name": "Traffic Cams", 'icon': 'assets/images/sign 1.png'},
    {'id': "8", "name": "DOT 511", 'icon': 'assets/images/dot_icon.png'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: TruckNavigationStaticDetails.locationOpt.length,
      vsync: this,
    );

    sheetScrollController.addListener(_handleSheetChange);
    navigationSheetScrollController.addListener(_handleNavigationSheetChange);

    // Initialize navigation sheet height
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateNavigationSheetHeight();
      }
    });

    textController.add(searchTextEditController);
    focusNode.add(FocusNode());

    searchFieldFocusNode.addListener(() {
      setState(() {});
      if (searchFieldFocusNode.hasFocus) {
        maximizeBottomSheet();
      } else {
        minimizeBottomSheet();
      }
    });

    // Listen to place type selection and trigger category search
    _selectedStation.addListener(() {
      final selected = _selectedStation.value;

      if (context.mounted) {
        if (selected != null) {
          final placeTypeName = selected['name'] ?? '';
          if (placeTypeName.isNotEmpty) {
            // Clear previous brands and selected brand when place type changes
            // context.read<TruckStopCubit>().clearState();
            context.read<TruckStopCubit>().searchByCategory(placeTypeName);
          }
          // When station is selected, ensure sheet is at most half
          final currentSize = sheetScrollController.size;
          if (currentSize > 0.55) {
            makeHalfBottomSheet();
          }
        } else {
          // Going back to main menu: clear UI state but preserve brand filter and place type
          context.read<TruckStopCubit>().clearAllTruckStops();
        }
      }
    });
  }

  @override
  void dispose() {
    sheetScrollController.removeListener(_handleSheetChange);
    navigationSheetScrollController.removeListener(
      _handleNavigationSheetChange,
    );
    navigationSheetHeight.dispose();
    sheetScrollController.dispose();
    navigationSheetScrollController.dispose();
    _tabController.dispose();
    // searchTextEditController.dispose();
    searchFieldFocusNode.dispose();
    for (var controller in textController) {
      controller.dispose();
    }
    for (var focusNode in focusNode) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _handleSheetChange() {
    // sheet size ranges from minChildSize → maxChildSize
    final double size = sheetScrollController.size;

    // When sheet is almost minimized
    if (size <= 0.26) {
      // adjust threshold if needed
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  void _handleNavigationSheetChange() {
    if (mounted) {
      _updateNavigationSheetHeight();
    }
  }

  void _updateNavigationSheetHeight() {
    if (navigationSheetScrollController.isAttached) {
      final double size = navigationSheetScrollController.size;
      final screenHeight = MediaQuery.of(context).size.height;

      Future.microtask(() {
        navigationSheetHeight.value = size * screenHeight;
      });
    }
  }

  makeHalfBottomSheet() {
    sheetScrollController.animateTo(
      0.55,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  maximizeBottomSheet() {
    sheetScrollController.animateTo(
      0.95,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  minimizeBottomSheet() {
    sheetScrollController.animateTo(
      0.26,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    searchFieldFocusNode.unfocus();
  }

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
    // showChangeMapSchemeDialog.value = false;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: BlocBuilder<TruckNavigationCubit, TruckNavigationState>(
        buildWhen: (previous, current) =>
            (previous.isNavigating != current.isNavigating ||
            previous.hasTapDestination != current.hasTapDestination ||
            previous.hasDirection != current.hasDirection ||
            previous.isNavigationCompleted != current.isNavigationCompleted),

        builder: (context, state) {
          log("home view rebuilding");
          return Stack(
            children: !state.isNavigating
                ? buildInitialUi(
                    context,
                    state.hasDirection,
                    state.hasTapDestination,
                  )
                : buildNavigationUi(state),
          );
        },
      ),
    );
  }

  Widget buildMapSchemeFloatingMenu() {
    return ValueListenableBuilder(
      valueListenable: showChangeMapSchemeDialog,
      builder: (context, value, child) {
        return GestureDetector(
          onTap: () {
            // showChangeMapSchemeDialog.value =
            //     !showChangeMapSchemeDialog.value;
            showMapSchemeDialog(context);
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),

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
                color: showChangeMapSchemeDialog.value
                    ? AppColorTheme().primary.withValues(alpha: 0.2)
                    : Colors.white,
              ),
              child: SvgPicture.asset(
                AppIcons.layerBoxIcon,
                colorFilter: showChangeMapSchemeDialog.value
                    ? ColorFilter.mode(AppColorTheme().primary, BlendMode.srcIn)
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Show business overview in modal bottom sheet
  List<Widget> buildInitialUi(
    BuildContext context,
    bool hasDirection,
    bool hasTapDirection,
  ) {
    return [
      // Background content
      MapView(),

      // side floating menu
      Positioned(
        right: 10,
        top: context.screenHeight * 0.02,
        child: SafeArea(child: HomeAppBar()),
      ),
      // side floating menu
      Positioned(
        right: 10,
        top: context.screenHeight * 0.12,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
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
                child: Image.asset('assets/images/bell.png'),
              ),
              buildMapSchemeFloatingMenu(),
              Container(
                width: 48,
                // height: 200,
                // padding: EdgeInsets.all(13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(50),
                    bottom: Radius.circular(50),
                  ),
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
                      onPressed: () => context
                          .read<TruckNavigationCubit>()
                          .mapZoomIn(context),
                      icon: SvgPicture.asset(AppIcons.zoomInIcon),
                    ),
                    IconButton(
                      onPressed: () => context
                          .read<TruckNavigationCubit>()
                          .mapZoomOut(context),
                      icon: SvgPicture.asset(AppIcons.zoomOutIcon),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => context
                    .read<TruckNavigationCubit>()
                    .focusOnCurrentLocation(),
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
                    color: Colors.white,
                  ),
                  child: SvgPicture.asset(
                    AppIcons.navigationIconGreen,
                    colorFilter: ColorFilter.mode(
                      Colors.black,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: () =>
                    context.read<TruckNavigationCubit>().animateToRoute(),

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
                    color: Colors.white,
                  ),
                  child: Image.asset('assets/images/ion_compass-sharp.png'),
                ),
              ),
            ],
          ),
        ),
      ),

      ValueListenableBuilder(
        valueListenable: _selectedStation,
        builder: (context, selectedStation, child) {
          // When station is selected, limit sheet to half (0.55) max
          final bool isStationSelected = selectedStation != null;
          return CustomDragableWidget(
            scrollController: sheetScrollController,

            maxSize: isStationSelected ? 0.55 : 0.95,
            snapSizes: isStationSelected ? [0.26, 0.55] : [0.26, 0.55, 0.95],
            childrens: [
              if (hasDirection) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Create a trip",
                      style: AppTextTheme().subHeadingText.copyWith(
                        fontWeight: AppFontWeight.semiBold,
                        fontSize: 20,
                      ),
                    ),

                    IconButton(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity(
                        horizontal: -4.0,
                        vertical: -4.0,
                      ),
                      onPressed: () {
                        context
                            .read<TruckNavigationCubit>()
                            .clearCurrentRouteDetail();
                        searchTextEditController.clear();
                        // searchFieldFocusNode.unfocus();
                      },
                      icon: Icon(Icons.close, color: Colors.black),
                    ),
                  ],
                ),
                20.h,
                TripDestinationWidget(),

                // TripDestinationWidget(
                //   focusNode: focusNode,
                //   textControllers: textController,
                //   readOnly: true,
                //   onDestinationFieldTap: () => HomeUtils.editLocationSheet(
                //     context,
                //     onContinue: (value) {
                //       if (value != null) {
                //         searchTextEditController.text = value;
                //       }
                //     },
                //   ),
                //   removeFieldTap: () {},
                // ),
                // 5.h,
                // TextButton(
                //   style: ButtonStyle(
                //     padding: WidgetStatePropertyAll(EdgeInsets.zero),
                //     visualDensity: VisualDensity(
                //       horizontal: -4.0,
                //       vertical: -4.0,
                //     ),
                //   ),
                //   onPressed: () {
                //     setState(() {
                //       textController.add(TextEditingController());
                //       focusNode.add(FocusNode());
                //     });
                //   },
                //   child: Row(
                //     spacing: 5,
                //     children: [
                //       Icon(Icons.add, size: 25),
                //       Text(
                //         "Add a stop",
                //         style: AppTextTheme().bodyText.copyWith(
                //           color: AppColorTheme().primary,
                //           fontSize: 16,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                20.h,
                DashedLine(),
                20.h,
                BlocBuilder<TruckNavigationCubit, TruckNavigationState>(
                  buildWhen: (p, c) => p.currentRoute != c.currentRoute,
                  builder: (context, state) {
                    return ListTile(
                      onTap: () =>
                          TruckNavigationUtils.openRouteDialogSheet(context),
                      // minLeadingWidth: 20,
                      // onTap: () {
                      //   TruckNavigationUtils.openRouteDialogSheet(context);
                      //   // if (state.availableDestinationRoutes?[index] != null) {
                      //   //   _truckGuidanceExample?.selectRouteAndDrawPolyLines(state.availableDestinationRoutes![index]);
                      //   // }
                      // },
                      contentPadding: EdgeInsets.symmetric(vertical: 5),
                      // leading: CircleAvatar(
                      //   radius: 25,
                      //   backgroundColor: Color(0xffF4F6F8),
                      //   child: SvgPicture.asset(AppIcons.truckIcon),
                      // ),
                      title: Row(
                        // crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              // "Via I-20E",
                              // "Route",
                              state.currentRoute?.getRouteName ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: AppTextTheme().bodyText.copyWith(
                                fontSize: 16,
                              ),
                            ),
                          ),
                          12.w,
                          Row(
                            spacing: 5,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                state.currentRoute?.formattedDuration ?? '',
                                // "2h 11m",
                                style: AppTextTheme().lightText.copyWith(
                                  color: AppColorTheme().primary,
                                ),
                              ),
                              Text(
                                state.currentRoute?.distanceInMiles ?? '',
                                //  "145 mi",
                                style: AppTextTheme().lightText.copyWith(
                                  color: AppColorTheme().secondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      subtitle: (state.currentRoute?.hasTolls ?? false)
                          ? Row(
                              spacing: 4,
                              children: [
                                Icon(
                                  Icons.warning_rounded,
                                  size: 16,
                                  color: Color(0xffFF4F5B),
                                ),
                                Expanded(
                                  child: Text(
                                    "This route requires tolls",
                                    style: AppTextTheme().lightText.copyWith(
                                      color: AppColorTheme().secondary,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : null,
                      trailing: SizedBox(
                        height: 48,
                        width: 110,
                        child: CustomButtonWidget(
                          title: 'Start Trip',
                          onPressed: () => context
                              .read<TruckNavigationCubit>()
                              .startNavigation(),
                          radius: 50,
                        ),
                      ),
                    );
                    // return Column(
                    //   children: List.generate(
                    //     state.availableDestinationRoutes?.length ?? 0,
                    //     (index) => ,
                    // ),
                    // );
                  },
                ),
                20.h,
                DashedLine(),
                20.h,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Settings",
                      style: AppTextTheme().subHeadingText.copyWith(
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        TruckSpecificationUtils.openSettingBottomSheet(
                          context,
                          onEditSuccess: () {
                            // minimizeBottomSheet();
                            context
                                .read<TruckNavigationCubit>()
                                .calculateRoute();
                            makeHalfBottomSheet();
                          },
                        );
                      },
                      icon: SvgPicture.asset(AppIcons.settingIcon),
                      style: ButtonStyle(
                        padding: WidgetStatePropertyAll(EdgeInsets.zero),
                        visualDensity: VisualDensity(
                          horizontal: -4.0,
                          vertical: -4.0,
                        ),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 5,
                  children: List.generate(
                    TruckNavigationStaticDetails.settingChipsList.length,
                    (index) => Chip(
                      deleteIconColor: AppColorTheme().secondary,
                      onDeleted: () {
                        setState(() {
                          TruckNavigationStaticDetails.settingChipsList
                              .removeAt(index);
                        });
                      },
                      deleteIconBoxConstraints: BoxConstraints(
                        maxHeight: 24,
                        maxWidth: 24,
                      ),
                      padding: EdgeInsets.symmetric(vertical: 0, horizontal: 3),
                      backgroundColor: Color(0xffF4F6F8),
                      deleteIcon: Icon(Icons.cancel),

                      label: Text(
                        TruckNavigationStaticDetails.settingChipsList[index],
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                        side: BorderSide(color: Colors.transparent),
                      ),
                    ),
                  ),
                ),
              ] else if (hasTapDirection) ...[
                BlocBuilder<TruckNavigationCubit, TruckNavigationState>(
                  buildWhen: (p, c) => p.tappedPlace != c.tappedPlace,
                  builder: (context, state) {
                    if (state.hasdestinationFromRecent) {
                      return showTappedAddressDetails();
                    } else {
                      return FutureDataBuilder(
                        future: state.tappedPlace,
                        loader: ClipRRect(
                          borderRadius: BorderRadiusGeometry.circular(10),
                          child: Shimmer(
                            color: Colors.greenAccent,
                            child: SizedBox(width: double.infinity, height: 80),
                          ),
                        ),
                        onSuccess: (place) {
                          if (place?.placeType == PlaceType.poi) {
                            return showTappedBusinessDetails(place);
                          } else {
                            return showTappedAddressDetails();
                          }
                        },
                      );
                      // return showTappedBusinessDetails();
                    }
                  },
                ),
              ] else if (selectedStation != null) ...[
                BlocBuilder<TruckStopCubit, TruckStopsState>(
                  buildWhen: (p, c) =>
                      p.showBusinessOverviewModal !=
                          c.showBusinessOverviewModal ||
                      p.selectedTruckStop != c.selectedTruckStop,
                  builder: (context, state) {
                    return state.showBusinessOverviewModal
                        ? showTappedBusinessDetails(
                            state.selectedTruckStop,
                            assetImage:
                                context
                                    .read<TruckStopCubit>()
                                    .placesLogoMap[state
                                    .selectedTruckStop
                                    ?.id] ??
                                '',
                            onBackPressed: () {
                              context
                                  .read<TruckStopCubit>()
                                  .clearSelectedTruckStop();
                            },
                            onTripPressed: () {
                              context
                                  .read<TruckStopCubit>()
                                  .createTripWithBusinessOverview();
                              _selectedStation.value = null;
                            },
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      _selectedStation.value = null;
                                      context
                                          .read<TruckStopCubit>()
                                          .clearAllTruckStops();
                                    },
                                    child: CircleAvatar(
                                      radius: 18,
                                      backgroundColor:
                                          AppColorTheme().whiteShade,
                                      child: const Icon(
                                        Icons.arrow_back_ios,
                                        color: Colors.black,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  16.w,
                                  Expanded(
                                    child: SizedBox(
                                      height: context.screenHeight * 0.042,
                                      child: ListView.separated(
                                        shrinkWrap: true,
                                        scrollDirection: Axis.horizontal,

                                        itemCount: TruckNavigationStaticDetails
                                            .quickPlaceTypes
                                            .length,
                                        separatorBuilder: (_, i) => 8.w,
                                        itemBuilder: (_, i) => InkWell(
                                          onTap: () {
                                            _selectedStation.value =
                                                TruckNavigationStaticDetails
                                                    .quickPlaceTypes[i];
                                          },
                                          child: HomeUtils.placeTypeChip(
                                            TruckNavigationStaticDetails
                                                .quickPlaceTypes[i],
                                            isSelected:
                                                selectedStation['name'] ==
                                                TruckNavigationStaticDetails
                                                    .quickPlaceTypes[i]['name'],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              15.h,
                              // Static brands filter UI - always shows default brands
                              BlocBuilder<TruckStopCubit, TruckStopsState>(
                                buildWhen: (previous, current) {
                                  // Get current category states
                                  final prevCategory =
                                      previous.currentPlaceType != null
                                      ? previous.categoriesSearchState
                                            .firstWhere(
                                              (c) =>
                                                  c.placeCategory ==
                                                  previous.currentPlaceType,
                                              orElse: () =>
                                                  PlaceCategoryTruckStopsState(),
                                            )
                                      : null;
                                  final currCategory =
                                      current.currentPlaceType != null
                                      ? current.categoriesSearchState.firstWhere(
                                          (c) =>
                                              c.placeCategory ==
                                              current.currentPlaceType,
                                          orElse: () =>
                                              PlaceCategoryTruckStopsState(),
                                        )
                                      : null;

                                  return previous.currentPlaceType !=
                                          current.currentPlaceType ||
                                      prevCategory?.availableBrands !=
                                          currCategory?.availableBrands ||
                                      prevCategory?.selectedBrands !=
                                          currCategory?.selectedBrands;
                                },
                                builder: (context, state) {
                                  // Get current category state
                                  final categoryState =
                                      state.currentPlaceType != null
                                      ? state.categoriesSearchState.firstWhere(
                                          (c) =>
                                              c.placeCategory ==
                                              state.currentPlaceType,
                                          orElse: () =>
                                              PlaceCategoryTruckStopsState(),
                                        )
                                      : null;

                                  // Always show default brands + "Other" if in availableBrands
                                  final brands =
                                      categoryState?.availableBrands ?? [];
                                  final selectedBrands =
                                      categoryState?.selectedBrands ?? [];

                                  // If no brands, show default brands anyway (static)
                                  final displayBrands = brands.isEmpty
                                      ? TruckStopCubit.defaultBrands
                                            .map((b) => b['name']!)
                                            .toList()
                                      : brands;

                                  // Helper function to get brand icon path
                                  String? getBrandIcon(String brand) {
                                    for (final defaultBrand
                                        in TruckStopCubit.defaultBrands) {
                                      if (defaultBrand['name'] == brand) {
                                        return defaultBrand['icon'];
                                      }
                                    }
                                    return null;
                                  }

                                  // Helper function to get deterministic color from brand name
                                  Color getBrandColor(String brand) {
                                    // List of predefined brand colors from AppColorTheme
                                    final brandColors = [
                                      const Color(0xFFFF9029), // orange
                                      const Color(0xFF4676F6), // blue
                                      const Color(0xFFFFC300), // yellowLight
                                      const Color(0xFFD0082C), // red4
                                    ];

                                    // Use brand name hash to deterministically select a color
                                    final hash = brand.hashCode;
                                    final colorIndex =
                                        hash.abs() % brandColors.length;

                                    return brandColors[colorIndex];
                                  }

                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: context.screenWidth * 0.026,
                                    ),
                                    child: SizedBox(
                                      height: 50,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: displayBrands.length,
                                        separatorBuilder: (_, __) => 12.w,
                                        itemBuilder: (context, index) {
                                          final brand = displayBrands[index];
                                          final isSelected = selectedBrands
                                              .contains(brand);
                                          final brandIcon = getBrandIcon(brand);
                                          final brandColor = brandIcon == null
                                              ? getBrandColor(brand)
                                              : null;
                                          final brandLetter = brand.isNotEmpty
                                              ? brand[0].toUpperCase()
                                              : '?';

                                          return InkWell(
                                            onTap: () {
                                              context
                                                  .read<TruckStopCubit>()
                                                  .toggleBrand(brand);
                                            },
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 30,
                                                  height: 30,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    // border: Border.all(
                                                    //   color: isSelected
                                                    //       ? AppColorTheme()
                                                    //             .primary
                                                    //       : Colors.grey,
                                                    //   width: isSelected ? 2 : 1,
                                                    // ),
                                                    color: brandIcon == null
                                                        ? brandColor
                                                              ?.withValues(
                                                                alpha:
                                                                    isSelected
                                                                    ? 1
                                                                    : 0.5,
                                                              )
                                                        : null,
                                                  ),
                                                  child: brandIcon != null
                                                      // Show brand image for default brands
                                                      ? ClipOval(
                                                          child: Opacity(
                                                            opacity: isSelected
                                                                ? 1.0
                                                                : 0.5,
                                                            child: Image.asset(
                                                              brandIcon,
                                                              width: 30,
                                                              height: 30,
                                                              fit: BoxFit.cover,
                                                            ),
                                                          ),
                                                        )
                                                      // Show first letter for "Other"
                                                      : Center(
                                                          child: Text(
                                                            brandLetter,
                                                            style: AppTextTheme()
                                                                .bodyText
                                                                .copyWith(
                                                                  fontSize: 18,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                        ),
                                                ),
                                                4.h,
                                                SizedBox(
                                                  width: 60,
                                                  child: Text(
                                                    brand,
                                                    style: AppTextTheme()
                                                        .lightText
                                                        .copyWith(
                                                          color: isSelected
                                                              ? const Color(
                                                                  0xFF000301,
                                                                )
                                                              : Colors.grey,
                                                          height: 1.40,
                                                          fontSize: 10,
                                                        ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                              10.h,
                              DefaultTabController(
                                length: TruckNavigationStaticDetails
                                    .placeTypeTabOpt
                                    .length,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.screenWidth * 0.026,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CustomTabBarWidget(
                                              options:
                                                  TruckNavigationStaticDetails
                                                      .placeTypeTabOpt,
                                            ),
                                          ),
                                          // 10.w,
                                          // Container(
                                          //   padding: EdgeInsets.symmetric(
                                          //     horizontal: 12,
                                          //     vertical: 8,
                                          //   ),
                                          //   decoration: BoxDecoration(
                                          //     borderRadius:
                                          //         BorderRadius.circular(50),
                                          //     color: const Color(0xffF5F7F9),
                                          //   ),
                                          //   child: Row(
                                          //     children: [
                                          //       Image.asset(
                                          //         AppImages.filterIcon,
                                          //         height: 24,
                                          //         width: 24,
                                          //       ),
                                          //       Text(
                                          //         "Filter",
                                          //         style: AppTextTheme().bodyText
                                          //             .copyWith(
                                          //               color: AppColorTheme()
                                          //                   .secondary,
                                          //               fontSize: 16,
                                          //               fontWeight:
                                          //                   FontWeight.w500,
                                          //             ),
                                          //       ),
                                          //     ],
                                          //   ),
                                          // ),
                                        ],
                                      ),
                                      15.h,
                                      SizedBox(
                                        height: context.screenHeight * 0.6,
                                        child: TabBarView(
                                          children: [
                                            // Category search results
                                            BlocBuilder<
                                              TruckStopCubit,
                                              TruckStopsState
                                            >(
                                              buildWhen: (previous, current) {
                                                // Get current category states
                                                final prevCategory =
                                                    previous.currentPlaceType !=
                                                        null
                                                    ? previous
                                                          .categoriesSearchState
                                                          .firstWhere(
                                                            (c) =>
                                                                c.placeCategory ==
                                                                previous
                                                                    .currentPlaceType,
                                                            orElse: () =>
                                                                PlaceCategoryTruckStopsState(),
                                                          )
                                                    : null;
                                                final currCategory =
                                                    current.currentPlaceType !=
                                                        null
                                                    ? current
                                                          .categoriesSearchState
                                                          .firstWhere(
                                                            (c) =>
                                                                c.placeCategory ==
                                                                current
                                                                    .currentPlaceType,
                                                            orElse: () =>
                                                                PlaceCategoryTruckStopsState(),
                                                          )
                                                    : null;

                                                return previous
                                                            .currentPlaceType !=
                                                        current
                                                            .currentPlaceType ||
                                                    prevCategory
                                                            ?.categorySearchResults !=
                                                        currCategory
                                                            ?.categorySearchResults ||
                                                    prevCategory
                                                            ?.selectedBrands !=
                                                        currCategory
                                                            ?.selectedBrands;
                                              },
                                              builder: (context, state) {
                                                // Get current category state
                                                final categoryState =
                                                    state.currentPlaceType !=
                                                        null
                                                    ? state
                                                          .categoriesSearchState
                                                          .firstWhere(
                                                            (c) =>
                                                                c.placeCategory ==
                                                                state
                                                                    .currentPlaceType,
                                                            orElse: () =>
                                                                PlaceCategoryTruckStopsState(),
                                                          )
                                                    : null;

                                                return FutureDataBuilder<
                                                  List<Place>
                                                >(
                                                  future: categoryState
                                                      ?.categorySearchResults,
                                                  onSuccess: (places) {
                                                    if (places == null ||
                                                        places.isEmpty) {
                                                      return Center(
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                20,
                                                              ),
                                                          child: Text(
                                                            'No ${selectedStation['name'] ?? 'places'} found nearby',
                                                            style: AppTextTheme()
                                                                .bodyText
                                                                .copyWith(
                                                                  color: AppColorTheme()
                                                                      .secondary,
                                                                ),
                                                          ),
                                                        ),
                                                      );
                                                    }

                                                    // Filter places by selected brands
                                                    final selectedBrands =
                                                        categoryState
                                                            ?.selectedBrands ??
                                                        [];
                                                    final truckStopCubit =
                                                        context
                                                            .read<
                                                              TruckStopCubit
                                                            >();
                                                    List<Place> filteredPlaces =
                                                        places;

                                                    // Filter if brands are selected
                                                    if (selectedBrands
                                                        .isNotEmpty) {
                                                      filteredPlaces = places.where((
                                                        place,
                                                      ) {
                                                        // Use the same brand categorization logic as cubit
                                                        final placeBrand =
                                                            truckStopCubit
                                                                .getBrandFromPlace(
                                                                  place,
                                                                );
                                                        // Include place if its categorized brand is in selected brands
                                                        return placeBrand !=
                                                                null &&
                                                            selectedBrands
                                                                .contains(
                                                                  placeBrand,
                                                                );
                                                      }).toList();

                                                      if (filteredPlaces
                                                          .isEmpty) {
                                                        return Center(
                                                          child: Padding(
                                                            padding:
                                                                EdgeInsets.all(
                                                                  20,
                                                                ),
                                                            child: Text(
                                                              'No locations found for selected brands',
                                                              style: AppTextTheme()
                                                                  .bodyText
                                                                  .copyWith(
                                                                    color: AppColorTheme()
                                                                        .secondary,
                                                                  ),
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    }
                                                    // If no brands selected, show all places

                                                    return SheetScrollBridge(
                                                      child: ListView.builder(
                                                      padding:
                                                          EdgeInsets.zero,
                                                      physics:
                                                          BouncingScrollPhysics(),
                                                      itemCount:
                                                          filteredPlaces
                                                              .length,
                                                      itemBuilder: (context, index) {
                                                        final place =
                                                            filteredPlaces[index];
                                                        return GestureDetector(
                                                          onTap: () {
                                                            context
                                                                .read<
                                                                  TruckStopCubit
                                                                >()
                                                                .showBusinessOverviewModal(
                                                                  place,
                                                                  fromMap:
                                                                      false,
                                                                );
                                                          },
                                                          child: Padding(
                                                            padding:
                                                                EdgeInsets.only(
                                                                  bottom: 16,
                                                                ),
                                                            child: PlaceDisplayWidget(
                                                              place: place
                                                                  .toPlaceDataModel,
                                                              image:
                                                                  context
                                                                      .read<
                                                                        TruckStopCubit
                                                                      >()
                                                                      .placesLogoMap[place
                                                                      .id] ??
                                                                  '',
                                                              isSaved: false,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                    );
                                                  },
                                                  loader: Column(
                                                    spacing: 10,
                                                    children: List.generate(
                                                      3,
                                                      (i) => Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              bottom: 16,
                                                            ),
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                          child: Shimmer(
                                                            color: Colors
                                                                .greenAccent,
                                                            child: SizedBox(
                                                              width: double
                                                                  .infinity,
                                                              height: 80,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            SheetScrollBridge(
                                                child: ListView.builder(
                                                padding: EdgeInsets.zero,
                                                physics:
                                                    BouncingScrollPhysics(),
                                                itemBuilder: (context, index) => GestureDetector(
                                                  // onTap: () {
                                                  //   setState(() {
                                                  //     searchTextEditController.text =
                                                  //         TruckNavigationStaticDetails
                                                  //             .placess[index]
                                                  //             .address;
                                                  //     place = TruckNavigationStaticDetails
                                                  //         .placess[index];
                                                  //   });
                                                  // },
                                                  child: PlaceDisplayWidget(
                                                    place:
                                                        TruckNavigationStaticDetails
                                                            .placess[index],
                                                    isSaved: true,
                                                  ),
                                                ),
                                                itemCount:
                                                    TruckNavigationStaticDetails
                                                        .placess
                                                        .length,
                                              ),
                                            ),

                                            SheetScrollBridge(
                                                child: ListView.builder(
                                                padding: EdgeInsets.zero,
                                                physics:
                                                    BouncingScrollPhysics(),
                                                itemBuilder: (context, index) =>
                                                    PlaceDisplayWidget(
                                                      place:
                                                          TruckNavigationStaticDetails
                                                              .terminals[index],
                                                      isSaved: true,
                                                    ),
                                                itemCount:
                                                    TruckNavigationStaticDetails
                                                        .terminals
                                                        .length,
                                              ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                  },
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: CustomTextfieldWidget(
                        focusNode: searchFieldFocusNode,
                        onTapOutside: (_) {},
                        // onEditingComplete: () {
                        //   context
                        //       .read<TruckNavigationCubit>()
                        //       .confirmDestination();
                        // },
                        onChanged: (text) {
                          setState(() {});
                          Future.delayed(Duration(milliseconds: 400), () {
                            if (context.mounted) {
                              context.read<TruckNavigationCubit>().searchPlaces(
                                text,
                              );
                              // context.read<MapCubit>().searchLocation(text, TruckGuidanceExample.myStartCoordinadtes);
                            }
                          });
                        },

                        prefixIcon: SvgPicture.asset(AppIcons.searchIcon),
                        hintText: "Find a destination...",
                        controller: searchTextEditController,
                        // suffixIcon: searchFieldFocusNode.hasFocus
                        //     ? searchTextEditController.text.isEmpty
                        //           ? SvgPicture.asset(AppIcons.mapSearchIcon)
                        //           : GestureDetector(
                        //               onTap: () {
                        //                 searchTextEditController.clear();
                        //                 setState(() {});
                        //               },
                        //               child: Icon(Icons.close),
                        //             )
                        //     : null,
                      ),
                    ),
                    8.w,
                    SizedBox(
                      height: 48,
                      width: 100,
                      child: CustomButtonWidget(
                        title: 'Trip',
                        onPressed: () {
                          Helpers.openBottomSheet(
                            context: context,
                            whenComplete: () {
                              minimizeBottomSheet();
                            },
                            child: CreateTripView(),
                          );
                        },

                        radius: 50,
                        icon: Icon(Icons.directions, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                // 15.h,
                // BlocBuilder<TruckNavigationCubit, TruckNavigationState>(
                //   buildWhen: (p, c) =>
                //       p.selectedSuggestion != c.selectedSuggestion,
                //   builder: (context, state) {
                //     return state.selectedSuggestion == null
                //         ? const SizedBox()
                //         : CustomButtonWidget(
                //             title: "Get Direction",
                //             onPressed: () {
                //               if (searchTextEditController.text.isNotEmpty) {
                //                 context
                //                     .read<TruckNavigationCubit>()
                //                     .calculateRoute();
                //               }
                //             },
                //             icon: Icon(Icons.directions, color: Colors.white),
                //           );
                //   },
                // ),
                if (!searchFieldFocusNode.hasFocus) ...[
                  15.h,
                  currentLocationTile(context),
                  // 10.h,
                  DashedLine(color: Color(0xffEBEEF2)),
                  15.h,
                  GridView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: TruckNavigationStaticDetails.stationList.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          if (TruckNavigationStaticDetails
                                  .stationList[index]['name'] ==
                              'More') {
                            HomeUtils.openMoreTruckStopsBottomSheet(context);
                          } else {
                            _selectedStation.value =
                                TruckNavigationStaticDetails.stationList[index];
                          }
                        },
                        child: Container(
                          // width: 100,
                          // padding: EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Color(0xffF4F6F8),
                            borderRadius: BorderRadius.circular(
                              16,
                            ), // optional rounded corners
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(
                                  0,
                                  0,
                                  0,
                                  0.04,
                                ), // shadow color
                                offset: Offset(0, 2), // x=0, y=2 (downwards)
                                blurRadius: 6, // soft shadow
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            spacing: 10,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                child: Image.asset(
                                  TruckNavigationStaticDetails
                                          .stationList[index]['icon'] ??
                                      '',
                                  width: 24,
                                  height: 24,
                                ),
                              ),
                              Text(
                                TruckNavigationStaticDetails
                                        .stationList[index]['name'] ??
                                    '',
                                style: AppTextTheme().bodyText,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
                if (searchFieldFocusNode.hasFocus &&
                    searchTextEditController.text.isEmpty) ...[
                  10.h,

                  CustomTabBarWidget(
                    options: TruckNavigationStaticDetails.locationOpt,
                    tabController: _tabController,
                  ),

                  15.h,
                  SizedBox(
                    height: context.screenHeight * 0.6,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        HomeUtils.showRecentSearches(
                          context,
                          onSelect: (searchHistory) {
                            searchTextEditController.text = searchHistory.title;
                            context
                                .read<TruckNavigationCubit>()
                                .selectRecentAsDestination(searchHistory);
                            makeHalfBottomSheet();
                          },
                        ),

                        ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) => GestureDetector(
                            child: PlaceDisplayWidget(
                              place:
                                  TruckNavigationStaticDetails.placess[index],
                              isSaved: true,
                            ),
                          ),
                          itemCount:
                              TruckNavigationStaticDetails.placess.length,
                        ),

                        ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) => PlaceDisplayWidget(
                            place:
                                TruckNavigationStaticDetails.terminals[index],
                            isSaved: true,
                          ),
                          itemCount:
                              TruckNavigationStaticDetails.terminals.length,
                        ),
                      ],
                    ),
                  ),
                ],
                if (searchFieldFocusNode.hasFocus &&
                    searchTextEditController.text.isNotEmpty) ...[
                  BlocBuilder<TruckNavigationCubit, TruckNavigationState>(
                    buildWhen: (previous, current) {
                      return previous.destinationSuggestions?.data !=
                          current.destinationSuggestions?.data;
                    },
                    builder: (context, state) {
                      return (state.destinationSuggestions?.data ?? [])
                              .isNotEmpty
                          ? ListView.separated(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              itemBuilder: (context, index) {
                                final Suggestion? item =
                                    state.destinationSuggestions?.data?[index];
                                log(item.toString());
                                return item == null
                                    ? SizedBox()
                                    : ListTile(
                                        onTap: () {
                                          searchTextEditController.text =
                                              item.title;

                                          context
                                              .read<TruckNavigationCubit>()
                                              .selectSuggestionAsDestination(
                                                item,
                                              );
                                          context
                                              .read<RecentSearchCubit>()
                                              .addSearchFromPlace(item.place!);

                                          // context
                                          //     .read<TruckNavigationCubit>()
                                          //     .confirmDestination();

                                          makeHalfBottomSheet();
                                          // context.read<MapCubit>().setDestinationCoordinate(item.place!.geoCoordinates!);
                                        },
                                        contentPadding: EdgeInsets.zero,
                                        leading: Column(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: Color(
                                                0xffF4F6F8,
                                              ),
                                              radius: 16,
                                              child: Image.asset(
                                                AppImages.suggestionPin,
                                                height: 20,
                                                width: 20,
                                              ),
                                            ),
                                            Text(
                                              item.place?.distanceInMiles ?? '',
                                              maxLines: 2,
                                              style: AppTextTheme().lightText
                                                  .copyWith(
                                                    fontSize: 12,
                                                    color: AppColorTheme()
                                                        .secondary,
                                                  ),
                                            ),
                                          ],
                                        ),

                                        title:
                                            item.place
                                                ?.buildSuggestionTitleWidget() ??
                                            SizedBox.shrink(),
                                        subtitle:
                                            item.place
                                                ?.buildSuggestionSubtitleWidget() ??
                                            SizedBox.shrink(),
                                      );
                              },
                              separatorBuilder: (context, index) => Divider(),
                              itemCount:
                                  state.destinationSuggestions?.data?.length ??
                                  0,
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
              ],
            ],
          );
        },
      ),
    ];
  }

  Widget showTappedAddressDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                context.read<TruckNavigationCubit>().removeTapDestination();
                searchTextEditController.clear();
              },
              child: CircleAvatar(
                radius: 25,
                backgroundColor: AppColorTheme().whiteShade,
                child: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black,
                  size: 18,
                ),
              ),
            ),
            8.w,
            Expanded(child: tapDestinationTile(context)),
            // 8.w,
            //
          ],
        ),
        20.h,
        DashedLine(color: Color(0xffEBEEF2)),
        20.h,
        // Business suggestions at this address
        BlocBuilder<TruckNavigationCubit, TruckNavigationState>(
          buildWhen: (p, c) => p.businessAtAddress != c.businessAtAddress,
          builder: (context, state) {
            if (state.businessAtAddress == null) {
              return SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Business suggestion',
                    style: AppTextTheme().bodyText.copyWith(
                      fontWeight: AppFontWeight.medium,
                      fontSize: 14,
                      color: AppColorTheme().grey,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  onTap: () {
                    context
                        .read<TruckNavigationCubit>()
                        .selectBusinessSuggestionAsDestination(
                          state.businessAtAddress!,
                        );
                    context.read<RecentSearchCubit>().addSearchFromPlace(
                      state.businessAtAddress!,
                    );

                    makeHalfBottomSheet();
                  },
                  leading: CircleAvatar(
                    backgroundColor: AppColorTheme().primary.withValues(
                      alpha: 0.52,
                    ),
                    radius: 20,
                    child: Icon(Icons.store),
                  ),
                  title: state.businessAtAddress?.buildSuggestionTitleWidget(),
                  subtitle: state.businessAtAddress
                      ?.buildSuggestionSubtitleWidget(),
                ),
                20.h,
              ],
            );
          },
        ),
        simpleTextTileWithIcon(AppImages.bookmarkIcon, 'Saved Place'),
        16.h,
        simpleTextTileWithIcon(
          AppImages.blackWhitLocationIcon,
          'Add New Place',
        ),
        32.h,
      ],
    );
  }

  Widget showTappedBusinessDetails(
    Place? place, {
    VoidCallback? onBackPressed,
    VoidCallback? onTripPressed,
    String? assetImage,
  }) {
    final String image = place?.getImage ?? '';
    final bool? isOpened = place?.details.openingHours.firstOrNull?.isOpen;
    final String? time =
        place?.details.openingHours.firstOrNull?.text.firstOrNull;
    final double? rating = place?.details.ratings.firstOrNull?.average;
    final int? ratingCount = place?.details.ratings.firstOrNull?.count;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 15.h,
        ListTile(
          contentPadding: EdgeInsets.zero,

          trailing: GestureDetector(
            onTap:
                onBackPressed ??
                () {
                  context.read<TruckNavigationCubit>().removeTapDestination();
                  searchTextEditController.clear();
                },
            child: const Icon(Icons.close, color: Colors.grey, size: 25),
          ),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
              image: image.isNotEmpty
                  ? DecorationImage(image: NetworkImage(image))
                  : assetImage != null
                  ? DecorationImage(image: AssetImage(assetImage))
                  : null,
            ),
          ),
          title: Text(
            place?.formattedTitle ?? '',
            style: AppTextTheme().headingText.copyWith(fontSize: 20),
          ),
          subtitle: Row(
            spacing: 3,
            children: [
              // ...List.generate(
              //   5,
              //   (index) =>
              //       SvgPicture.asset(AppIcons.ratingIcon),
              // ),
              if (rating != null) ...[
                CustomRatingIndicator(rating: rating),
                Text(
                  rating.toString(),
                  style: AppTextTheme().lightText.copyWith(
                    color: Color(0xffFF8800),
                  ),
                ),
              ],

              Text.rich(
                TextSpan(
                  children: [
                    if (ratingCount != null) ...[
                      TextSpan(text: "($ratingCount)"),
                      TextSpan(
                        text: "  •  ", // example extra text
                        style: AppTextTheme().lightText.copyWith(
                          fontSize: 16,
                          color: AppColorTheme().secondary,
                        ),
                      ),
                    ],

                    TextSpan(
                      text: place?.details.categories.firstOrNull?.name ?? '',
                    ),
                    TextSpan(
                      text: "  •  ", // example extra text
                      style: AppTextTheme().lightText.copyWith(
                        fontSize: 16,
                        color: AppColorTheme().secondary,
                      ),
                    ),

                    TextSpan(text: place?.distanceInMiles ?? ''),
                  ],
                  style: AppTextTheme().lightText.copyWith(
                    color: AppColorTheme().secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        10.h,
        Row(
          spacing: 10,
          children: [
            Expanded(
              child: CustomButtonWidget(
                onPressed:
                    onTripPressed ??
                    () {
                      if ((place?.title ?? '').isNotEmpty) {
                        searchTextEditController.text = place?.title ?? '';
                      }

                      // minimizeBottomSheet();
                      context.read<TruckNavigationCubit>().calculateRoute();
                      makeHalfBottomSheet();
                    },
                title: "Trip",
                icon: Icon(Icons.directions, color: Colors.white),
              ),
            ),
            Expanded(
              child: CustomButtonWidget(
                onPressed: () {},
                title: "Save",
                bgColor: AppColorTheme().white,
                textColor: AppColorTheme().black,
                bdColor: AppColorTheme().secondarButtonColor,
                icon: Icon(
                  Icons.bookmark_border_outlined,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
            Expanded(
              child: CustomButtonWidget(
                onPressed: () {},
                title: "Call",
                bgColor: AppColorTheme().white,
                textColor: AppColorTheme().black,
                bdColor: AppColorTheme().secondarButtonColor,

                icon: Icon(Icons.phone_outlined, color: Colors.black, size: 20),
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
          title: Text(
            place?.formattedSubtitle ?? '',
            style: AppTextTheme().lightText.copyWith(fontSize: 16),
          ),
        ),
        ListTile(
          leading: Icon(Icons.schedule, color: Colors.black),
          horizontalTitleGap: 5,
          title: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: isOpened == null
                      ? 'N/A'
                      : isOpened
                      ? "Opened"
                      : "Closed",
                  style: AppTextTheme().lightText.copyWith(
                    fontSize: 16,
                    color: isOpened == null
                        ? AppColorTheme().lightGrey
                        : isOpened
                        ? AppColorTheme().primary
                        : Colors.red,
                  ),
                ),
                if (time != null) ...[
                  TextSpan(
                    text: "  •  ", // example extra text
                    style: AppTextTheme().lightText.copyWith(
                      fontSize: 16,
                      color: AppColorTheme().secondary,
                    ),
                  ),

                  TextSpan(
                    text:
                        place
                            ?.details
                            .openingHours
                            .firstOrNull
                            ?.text
                            .firstOrNull ??
                        '',
                  ),
                ],
              ],
            ),
          ),
        ),
        ListTile(
          leading: Icon(Icons.phone_outlined, color: Colors.black),
          horizontalTitleGap: 5,
          title: Text(
            place
                    ?.details
                    .contacts
                    .firstOrNull
                    ?.landlinePhones
                    .firstOrNull
                    ?.phoneNumber ??
                place
                    ?.details
                    .contacts
                    .firstOrNull
                    ?.mobilePhones
                    .firstOrNull
                    ?.phoneNumber ??
                'N/A',

            // "(406) 555-0120 ",
            style: AppTextTheme().lightText.copyWith(fontSize: 16),
          ),
        ),
        ListTile(
          leading: Icon(Icons.language, color: Colors.black),
          horizontalTitleGap: 5,
          title: Text(
            place
                    ?.details
                    .contacts
                    .firstOrNull
                    ?.websites
                    .firstOrNull
                    ?.address ??
                'N/A',
            style: AppTextTheme().lightText.copyWith(fontSize: 16),
          ),
        ),
        10.h,
        DashedLine(),
        15.h,
        Wrap(
          spacing: 8, // space between chips
          runSpacing: 8, // space between lines
          children: (place?.amenitiesAsList ?? []).map((e) {
            return Chip(
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.only(right: 8),
              avatar: Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 24,
              ),
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
      ],
    );
  }

  List<Widget> buildNavigationUi(TruckNavigationState state) {
    final mq = MediaQuery.of(context);
    final stableScreenHeight = mq.size.height + mq.viewInsets.bottom;
    return [
      MapView(height: stableScreenHeight * 0.66),
      if (state.isNavigating &&
          (state.isOffRoute || state.isRecalculatingRoute))
        BlocBuilder<TruckNavigationCubit, TruckNavigationState>(
          buildWhen: (p, c) =>
              p.isOffRoute != c.isOffRoute ||
              p.isRecalculatingRoute != c.isRecalculatingRoute,
          builder: (context, navState) {
            return Positioned(
              top: 12,
              left: 20,
              right: 20,
              child: SafeArea(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: navState.isRecalculatingRoute
                          ? Colors.blue.shade700
                          : Colors.orange.shade700,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (navState.isRecalculatingRoute)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        else
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            navState.isRecalculatingRoute
                                ? 'Recalculating route…'
                                : 'You\'re off route. Recalculating…',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      // Positioned(bottom: 100, top: 0, left: 0, right: 0, child: MapView()),
      if (!state.isNavigationCompleted)
        BlocBuilder<TruckNavigationCubit, TruckNavigationState>(
          buildWhen: (p, c) =>
              p.maneuverProgresses != c.maneuverProgresses ||
              p.isNavigationCompleted != c.isNavigationCompleted,
          builder: (context, state) {
            if (state.currentRoute == null ||
                state.maneuverProgresses.isEmpty) {
              return SizedBox();
            } else {
              final ManeuverProgress? nextManuever =
                  state.maneuverProgresses.firstOrNull;

              if (nextManuever == null) {
                return SizedBox();
              }

              ManeuverProgress? afterNextManuever;
              bool showAfterNext = false;
              if (state.maneuverProgresses.length > 1) {
                num distanceBetweenFirstAndNextManuever = 0;
                afterNextManuever = state.maneuverProgresses[1];

                distanceBetweenFirstAndNextManuever =
                    afterNextManuever.remainingDistanceInMeters -
                    nextManuever.remainingDistanceInMeters;

                // checking if distance has more than 250ft
                showAfterNext =
                    distanceBetweenFirstAndNextManuever > 0 &&
                    distanceBetweenFirstAndNextManuever <= 250.feetToMeters;
              }

              return Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: SafeArea(
                  child: Container(
                    // height: 250,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white, // background
                      borderRadius: (showAfterNext)
                          ? BorderRadius.only(
                              topLeft: Radius.circular(20),
                              // bottomLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            )
                          : BorderRadius.circular(20), // border-radius: 20px
                      border: Border.all(
                        color: const Color(0xFFEBEEF2), // #EBEEF2
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(
                            136,
                            139,
                            161,
                            0.18,
                          ), // rgba(136,139,161,0.18)
                          offset: const Offset(4, 4), // x:4px, y:4px
                          blurRadius: 24, // blur
                          spreadRadius: -4, // -4px spread
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      spacing: 10,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 10,
                          children: [
                            Column(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColorTheme().primary,
                                  child: Icon(
                                    state.currentRoute?.maneuverInstructionIcon(
                                      nextManuever.maneuverIndex,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  state.currentRoute
                                          ?.getAdjustedDistanceToManeuver(
                                            nextManuever.maneuverIndex,
                                            nextManuever
                                                .remainingDistanceInMeters
                                                .toDouble(),
                                            state.currentNavigationLocation,
                                          )
                                          .meterInMiles ??
                                      nextManuever
                                          .remainingDistanceInMeters
                                          .meterInMiles,
                                  style: AppTextTheme().bodyText.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColorTheme().primary,
                                  ),
                                ),
                              ],
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state.currentRoute?.maneuverInstruction(
                                          nextManuever.maneuverIndex,
                                        ) ??
                                        '',
                                    // state.currentRoute
                                    //         ?.formattedManeuverInstructionWithRemainingDistance(
                                    //           nextManuever.maneuverIndex,
                                    //           nextManuever.remainingDistanceInMeters
                                    //               .toDouble(),
                                    //         ) ??
                                    //     '',
                                    style: AppTextTheme().bodyText.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    state.currentRoute?.maneuverNextAddress(
                                          nextManuever.maneuverIndex,
                                        ) ??
                                        '',
                                    style: AppTextTheme().lightText.copyWith(
                                      color: AppColorTheme().secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColorTheme().whiteShade,
                              child: Icon(
                                Icons.volume_off_outlined,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          },
        ),
      if (!state.isNavigationCompleted)
        BlocBuilder<TruckNavigationCubit, TruckNavigationState>(
          buildWhen: (p, c) =>
              p.maneuverProgresses != c.maneuverProgresses ||
              p.isNavigationCompleted != c.isNavigationCompleted,
          builder: (context, state) {
            if (state.currentRoute == null ||
                state.maneuverProgresses.isEmpty) {
              return SizedBox();
            } else {
              final ManeuverProgress? nextManuever =
                  state.maneuverProgresses.firstOrNull;

              if (nextManuever == null) {
                return SizedBox();
              }

              ManeuverProgress? afterNextManuever;
              num distanceBetweenFirstAndNextManuever = 0;
              bool showAfterNext = false;

              if (state.maneuverProgresses.length > 1) {
                afterNextManuever = state.maneuverProgresses[1];

                distanceBetweenFirstAndNextManuever =
                    afterNextManuever.remainingDistanceInMeters -
                    nextManuever.remainingDistanceInMeters;

                //  checking if distance has more than 250ft
                showAfterNext =
                    distanceBetweenFirstAndNextManuever > 0 &&
                    distanceBetweenFirstAndNextManuever <= 250.feetToMeters;
              }
              if (afterNextManuever != null && showAfterNext) {
                return Positioned(
                  top: 120,
                  left: 20,
                  child: SafeArea(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white, // background
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ), // border-radius: 20px
                        border: Border.all(
                          color: const Color(0xFFEBEEF2), // #EBEEF2
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(
                              136,
                              139,
                              161,
                              0.18,
                            ), // rgba(136,139,161,0.18)
                            offset: const Offset(4, 4), // x:4px, y:4px
                            blurRadius: 24, // blur
                            spreadRadius: -4, // -4px spread
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundColor: AppColorTheme().lightGrey,
                            child: Icon(
                              state.currentRoute?.maneuverInstructionIcon(
                                afterNextManuever.maneuverIndex,
                              ),
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            distanceBetweenFirstAndNextManuever
                                .meterInMiles, // "${afterNextManuever.remainingDistanceInMeters.toDouble().toStringAsFixed(0)}m",
                            style: AppTextTheme().bodyText.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColorTheme().lightGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                return SizedBox.shrink();
              }
            }
          },
        ),

      if (!state.isNavigationCompleted)
        ValueListenableBuilder<double>(
          valueListenable: navigationSheetHeight,
          builder: (context, sheetHeight, child) {
            // Calculate bottom position: sheet height + padding (20px)
            final bottomPosition = (sheetHeight > 0 ? sheetHeight + 20 : 285)
                .toDouble();
            return Positioned(
              bottom: bottomPosition,
              left: 20,
              right: 20,
              child: BlocBuilder<TruckNavigationCubit, TruckNavigationState>(
                buildWhen: (previous, current) =>
                    previous.speedLimit != current.speedLimit ||
                    previous.currentSpeed != current.currentSpeed,
                builder: (context, state) {
                  return Row(
                    children: [
                      Container(
                        height: 60,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white, // background
                          borderRadius: BorderRadius.circular(
                            20,
                          ), // border-radius: 20px
                          border: Border.all(
                            color: const Color(0xFFEBEEF2), // #EBEEF2
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromRGBO(
                                136,
                                139,
                                161,
                                0.18,
                              ), // rgba(136,139,161,0.18)
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
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  state.speedLimit ?? "0",
                                  style: AppTextTheme().subHeadingText.copyWith(
                                    fontSize: 24,
                                  ),
                                ),
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
                                    Text(
                                      state.currentSpeed ?? "0",
                                      style: AppTextTheme().subHeadingText
                                          .copyWith(fontSize: 24),
                                    ),
                                    Text(
                                      "mph",
                                      style: AppTextTheme().lightText,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),

      ValueListenableBuilder<double>(
        valueListenable: navigationSheetHeight,
        builder: (context, sheetHeight, child) {
          // Calculate bottom position: sheet height + padding (20px)
          final bottomPosition =
              (sheetHeight > 0
                      ? sheetHeight + 20
                      : (state.isNavigationCompleted ? 220.0 : 300.0))
                  .toDouble();
          return Positioned(
            bottom: bottomPosition,
            right: 20,
            child: Row(
              children: [
                Column(
                  spacing: 20,
                  children: [
                    buildMapSchemeFloatingMenu(),
                    InkWell(
                      onTap: () =>
                          // context.read<TruckNavigationCubit>().focusOnCurrentLocation(),
                          context
                              .read<TruckNavigationCubit>()
                              .toggleCameraControll(),
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
                          color: Colors.white,
                        ),
                        child:
                            BlocBuilder<
                              TruckNavigationCubit,
                              TruckNavigationState
                            >(
                              buildWhen: (p, c) =>
                                  p.cameraControlledByNavigator !=
                                  c.cameraControlledByNavigator,
                              builder: (context, state) {
                                if (state.cameraControlledByNavigator) {
                                  return Image.asset(
                                    'assets/images/ion_compass-sharp.png',
                                  );

                                  // return Icon(
                                  //   Icons.pan_tool_rounded,
                                  //   color: Colors.black,
                                  //   size: 20,
                                  // );
                                } else {
                                  return SvgPicture.asset(
                                    AppIcons.navigationIconGreen,
                                    colorFilter: ColorFilter.mode(
                                      Colors.black,
                                      BlendMode.srcIn,
                                    ),
                                  );
                                }
                              },
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),

      CustomDragableWidget(
        scrollController: navigationSheetScrollController,
        initialSize: 0.34,
        miniSize: 0.34,
        maxSize: state.isNavigationCompleted ? 0.34 : 0.95,
        snapSizes: state.isNavigationCompleted ? [0.34] : [0.34, 0.55, 0.95],

        bottomWidget: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: CustomButtonWidget(
              bgColor: AppColorTheme().red2,
              textColor: Colors.white,
              icon: Icon(Icons.double_arrow, color: Colors.white, size: 18),
              isRightSide: true,
              title: "End Trip",
              onPressed: () {
                context.read<TruckNavigationCubit>().stopNavigation();
                searchTextEditController.clear();
                // TruckNavigationUtils.saveDialog(context);
              },
            ),
          ),
        ),
        childrens: [
          BlocBuilder<TruckNavigationCubit, TruckNavigationState>(
            buildWhen: (previous, current) =>
                previous.nextTargetIndex != current.nextTargetIndex,
            builder: (context, _state) {
              final bool isDestination =
                  _state.nextTargetIndex == (_state.locationPoints!.length - 1);

              return Row(
                mainAxisAlignment: MainAxisAlignment.start,
                spacing: 10,
                children: [
                  isDestination
                      ? Image.asset(
                          AppImages.redLocationIcon,
                          width: 48,
                          height: 48,
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColorTheme().white,
                            border: Border.all(
                              width: 5,
                              color: AppColorTheme().red2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _state.nextTargetIndex.toString(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                  Expanded(
                    child: Column(
                      spacing: 2,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (state.isNavigationCompleted)
                          Text(
                            'You’ve arrived at your destination.',
                            style: AppTextTheme().subHeadingText.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        Text(
                          _state
                                  .locationPoints?[_state.nextTargetIndex]
                                  .title ??
                              '',
                          style: AppTextTheme().subHeadingText.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _state
                                  .locationPoints?[_state.nextTargetIndex]
                                  .subTitle ??
                              '',
                          overflow: TextOverflow.ellipsis,
                          style: AppTextTheme().subHeadingText.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xff888BA1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          20.h,
          DashedLine(),
          if (!state.isNavigationCompleted) ...[
            20.h,
            BlocBuilder<TruckNavigationCubit, TruckNavigationState>(
              buildWhen: (p, c) =>
                  p.remainingDistanceInMeters != c.remainingDistanceInMeters ||
                  p.remainingDuration != c.remainingDuration ||
                  p.currentRoute != c.currentRoute ||
                  p.isNavigating != c.isNavigating,
              builder: (context, state) => _RemainingRouteStats(state: state),
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
                    'My Current Location',
                    // "Times Square, New York, NY, USA",
                    style: AppTextTheme().bodyText.copyWith(
                      fontWeight: AppFontWeight.semiBold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            20.h,
            TruckNavigationUtils.buildRouteDetails(state.currentRoute!),
            20.h,
            Row(
              spacing: 10,
              children: [
                Icon(Icons.location_on),
                Expanded(
                  child: Text(
                    state.hasTapDestination
                        ? state.tappedPlace?.data?.address.addressText ?? ''
                        : state
                                  .selectedSuggestion
                                  ?.place
                                  ?.address
                                  .addressText ??
                              searchTextEditController.text,
                    // searchTextEditController.text,
                    // "Times Square, New York, NY, USA",
                    style: AppTextTheme().bodyText.copyWith(
                      fontWeight: AppFontWeight.semiBold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            20.h,
          ],
        ],
      ),
    ];
  }

  Widget _styleButton(
    BuildContext context,
    String label,
    MapScheme scheme,
    String icon,
    int index,
  ) {
    return ValueListenableBuilder(
      valueListenable: selectIndexMapView,
      builder: (_, v, c) {
        bool isSelect = v == index;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              context.read<TruckNavigationCubit>().changeMapScheme(scheme);
              selectIndexMapView.value = index;
              context.popPage();
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
                    border: isSelect
                        ? Border.all(color: AppColorTheme().primary)
                        : null,
                    image: DecorationImage(
                      image: AssetImage(icon),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Text(
                  label,
                  style: AppTextTheme().bodyText.copyWith(
                    color: isSelect
                        ? AppColorTheme().primary
                        : AppColorTheme().secondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget currentLocationTile(BuildContext context) {
    return BlocBuilder<TruckNavigationCubit, TruckNavigationState>(
      buildWhen: (p, c) => p.currentPlace != c.currentPlace,
      builder: (context, state) => FutureDataBuilder(
        future: state.currentPlace,

        onSuccess: (place) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: AppColorTheme().primary.withValues(alpha: 0.2),
            child: SvgPicture.asset(AppIcons.navigationIconGreen),
          ),
          title: place?.buildSuggestionTitleWidget(),
          subtitle: place?.buildSuggestionSubtitleWidget(),
        ),

        loader: ClipRRect(
          borderRadius: BorderRadiusGeometry.circular(10),
          child: Shimmer(
            color: Colors.greenAccent,
            child: SizedBox(width: double.infinity, height: 80),
          ),
        ),
      ),
    );
  }

  Widget tapDestinationTile(BuildContext context) {
    return BlocBuilder<TruckNavigationCubit, TruckNavigationState>(
      buildWhen: (p, c) => p.tappedPlace != c.tappedPlace,
      builder: (context, state) => state.hasdestinationFromRecent
          ? ListTile(
              contentPadding: EdgeInsets.zero,

              trailing: GestureDetector(
                onTap: () {
                  if ((state.destinationFromRecent?.title ?? '').isNotEmpty) {
                    searchTextEditController.text =
                        state.destinationFromRecent?.title ?? '';
                  }

                  // minimizeBottomSheet();
                  context.read<TruckNavigationCubit>().calculateRoute();
                  makeHalfBottomSheet();
                },
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColorTheme().primary,
                  child: const Icon(
                    Icons.directions,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              title: state.destinationFromRecent?.buildSuggestionTitleWidget(),
              subtitle: state.destinationFromRecent
                  ?.buildSuggestionSubtitleWidget(),
            )
          : FutureDataBuilder(
              future: state.tappedPlace,
              onSuccess: (place) => ListTile(
                contentPadding: EdgeInsets.zero,

                trailing: GestureDetector(
                  onTap: () {
                    if ((place?.title ?? '').isNotEmpty) {
                      searchTextEditController.text = place?.title ?? '';
                    }

                    // minimizeBottomSheet();
                    context.read<TruckNavigationCubit>().calculateRoute();
                    makeHalfBottomSheet();
                  },
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColorTheme().primary,
                    child: const Icon(
                      Icons.directions,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                title: place?.buildSuggestionTitleWidget(),
                subtitle: place?.buildSuggestionSubtitleWidget(),
              ),
              loader: ClipRRect(
                borderRadius: BorderRadiusGeometry.circular(10),
                child: Shimmer(
                  color: Colors.greenAccent,
                  child: SizedBox(width: double.infinity, height: 80),
                ),
              ),
            ),
    );
  }

  Widget simpleTextTileWithIcon(String icon, text) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xffEBEEF2), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      // height: context.screenHeight * 0.042,
      child: Row(
        children: [
          SizedBox.square(dimension: 24, child: Image.asset(icon)),
          8.w,
          Text(
            'Saved Place',
            style: AppTextTheme().bodyText.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          Spacer(),
          SizedBox.square(
            dimension: 24,
            child: Image.asset(AppImages.arrowForward),
          ),
        ],
      ),
    );
  }

  Future<dynamic> showMapSchemeDialog(BuildContext context) {
    return showDialog(
      context: context,

      builder: (context) => Material(
        color: Colors.transparent,

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            122.h,
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),

              // width: 271,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        context.popPage();
                        // showChangeMapSchemeDialog.value = false;
                      },
                      child: Icon(Icons.close, color: Color(0xff8C93A4)),
                    ),
                  ),
                  16.h,
                  Row(
                    spacing: 20,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(
                      TruckNavigationStaticDetails.mapSchemes.length,
                      (index) {
                        final item =
                            TruckNavigationStaticDetails.mapSchemes[index];
                        return _styleButton(
                          context,
                          item.label,
                          item.scheme,
                          item.icon,
                          index,
                        );
                      },
                    ),
                  ),
                  15.h,
                  DashedLine(height: 1),
                  15.h,
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: mapFeature.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 44,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemBuilder: (_, i) => ValueListenableBuilder(
                      valueListenable: _selectedMapFeature,
                      builder: (context, value, child) {
                        final isSelected = value.contains(mapFeature[i]['id']);
                        return GestureDetector(
                          onTap: () {
                            final List<String> uL = List.from(
                              _selectedMapFeature.value,
                            );
                            if (isSelected) {
                              uL.remove(mapFeature[i]['id']);
                            } else {
                              uL.add(mapFeature[i]['id'].toString());
                            }
                            _selectedMapFeature.value = uL;
                          },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColorTheme().white,
                              border: Border.all(
                                color: isSelected
                                    ? AppColorTheme().primary
                                    : Color(0xffEBEEF2),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),

                            child: Row(
                              children: [
                                Image.asset(
                                  mapFeature[i]['icon'].toString(),
                                  width: 20,
                                  height: 20,
                                ),
                                8.w,
                                Text(
                                  mapFeature[i]['name'].toString(),
                                  style: AppTextTheme().bodyText.copyWith(
                                    color: AppColorTheme().secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void onTruckRestrictionWarning(String message) {
    SnackbarUtils.showWarningSnackBar(context, message);
  }
}

class PlaceDisplayWidget extends StatelessWidget {
  final bool? isSaved;
  final String? image;
  const PlaceDisplayWidget({
    super.key,
    this.place,
    this.isSaved = false,
    this.image,
  });

  final PlaceDataModel? place;

  @override
  Widget build(BuildContext context) {
    log("network image ${place?.networkImage.toString()}");

    return Row(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Color(0xffF4F6F8),
          child: CircleAvatar(
            radius: 13,
            backgroundImage: (place?.networkImage ?? '').isNotEmpty
                ? CachedNetworkImageProvider(place?.networkImage ?? '')
                : (image ?? '').isNotEmpty
                ? AssetImage(image ?? '')
                : (place?.icon ?? '').isNotEmpty
                ? AssetImage(place?.icon ?? '')
                : null,
          ),
        ),
        Expanded(
          child: Column(
            spacing: 5,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      place?.title ?? '',
                      style: AppTextTheme().headingText.copyWith(fontSize: 16),
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Color(0xFFEBEEF2),
                        width: 1,
                      ), // rgba(235, 238, 242, 1)
                      borderRadius: BorderRadius.circular(8), // Optional
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(
                            0,
                            0,
                            0,
                            0.04,
                          ), // rgba(0, 0, 0, 0.04)
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
                  Text(
                    place?.rating.toString() ?? '',
                    style: AppTextTheme().bodyText.copyWith(
                      color: Color(0xffFF8800),
                    ),
                  ),
                  Text(
                    "(${place?.reviewCount ?? ''})",
                    style: AppTextTheme().bodyText.copyWith(
                      color: AppColorTheme().secondary,
                    ),
                  ),
                  Text(
                    "  • ${place?.storeType ?? ''} • ${place?.distance ?? '0'} mi",
                    style: AppTextTheme().bodyText.copyWith(
                      color: AppColorTheme().secondary,
                    ),
                  ),
                ],
              ),
              Text(place?.address ?? '', style: AppTextTheme().bodyText),
              Row(
                children: [
                  Text(
                    place?.shopStatus == true
                        ? "Opened"
                        : place?.shopStatus == false
                        ? "Closed"
                        : 'N/A',
                    // place?.shopStatus == "Open" ? "Opened" : "Closed",
                    style: AppTextTheme().bodyText.copyWith(
                      color: place?.shopStatus == true
                          ? AppColorTheme().primary
                          : Colors.redAccent,
                    ),
                  ),
                  Text(
                    // "  • ${place?.shopStatus == true ? "Closes" : "Opens"} at ${place?.time} ",
                    "  • ${place?.time}",
                    style: AppTextTheme().bodyText.copyWith(
                      color: AppColorTheme().secondary,
                    ),
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

/// Displays ETA, remaining duration, and remaining distance, updating from
/// [RouteProgress] during navigation when available.
class _RemainingRouteStats extends StatelessWidget {
  const _RemainingRouteStats({required this.state});

  final TruckNavigationState state;

  static String _formatRemainingDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final useRemaining =
        state.isNavigating &&
        state.remainingDuration != null &&
        state.remainingDistanceInMeters != null;

    final etaStr = useRemaining
        ? TimeOfDay.fromDateTime(
            DateTime.now().add(state.remainingDuration!),
          ).format(context)
        : (state.currentRoute?.formattedETA(context) ?? '');
    final durationStr = useRemaining
        ? _formatRemainingDuration(state.remainingDuration!)
        : (state.currentRoute?.formattedDuration ?? '');
    final milesStr = useRemaining
        ? (state.remainingDistanceInMeters! / 1609.34).toStringAsFixed(1)
        : (state.currentRoute?.distanceInMilesINNumber ?? '');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              etaStr,
              style: AppTextTheme().subHeadingText.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Arrival',
              style: AppTextTheme().subHeadingText.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xff888BA1),
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              durationStr,
              style: AppTextTheme().subHeadingText.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'hours',
              style: AppTextTheme().subHeadingText.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xff888BA1),
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              milesStr,
              style: AppTextTheme().subHeadingText.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'miles',
              style: AppTextTheme().subHeadingText.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xff888BA1),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
