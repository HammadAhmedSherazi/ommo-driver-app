import 'dart:developer';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/search.dart';
import 'package:ommo/custom_widget/custom_widget.dart';
import 'package:ommo/custom_widget/future_data_builder.dart';
import 'package:ommo/home/view/home_app_bar.dart';
import 'package:ommo/home/view/home_utils.dart';
import 'package:ommo/home/view/map_view.dart';
import 'package:ommo/home/view/trip_destination_widget.dart';
import 'package:ommo/home/view/truck_specification/truck_specification_utils.dart';
import 'package:ommo/logic/cubit/truck_navigation/truck_navigation_cubit.dart';
import 'package:ommo/logic/cubit/truck_navigation/truck_navigation_state.dart';
import 'package:ommo/home/view/truck_navigation/truck_navigation_static_details.dart';
import 'package:ommo/home/view/truck_navigation/truck_navigation_utils.dart';
import 'package:ommo/services/hive/recent_search/cubit/recent_search_cubit.dart';
import 'package:ommo/services/hive/recent_search/model/recent_search_model.dart';
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
  PlaceDataModel? place;
  int selectLocationOpt = 0;
  // bool isSetDirection = false;

  final DraggableScrollableController sheetScrollController =
      DraggableScrollableController();

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

    textController.add(searchTextEditController);
    focusNode.add(FocusNode());
    searchFieldFocusNode.addListener(() {
      setState(() {});
      if (searchFieldFocusNode.hasFocus) {
        sheetScrollController.animateTo(
          0.95,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        sheetScrollController.animateTo(
          0.26,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
            previous.hasDirection != current.hasDirection),

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
        child: HomeAppBar(),
      ),
      // side floating menu
      Positioned(
        right: 10,
        top: context.screenHeight * 0.12,
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
            ValueListenableBuilder(
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
                            ? ColorFilter.mode(
                                AppColorTheme().primary,
                                BlendMode.srcIn,
                              )
                            : null,
                      ),
                    ),
                  ),
                );
              },
            ),
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
                    onPressed: () =>
                        context.read<TruckNavigationCubit>().mapZoomIn(context),
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
              onTap: () =>
                  context.read<TruckNavigationCubit>().focusOnCurrentLocation(),
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
                  colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
                ),
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
              child: Image.asset('assets/images/ion_compass-sharp.png'),
            ),
          ],
        ),
      ),

      ValueListenableBuilder(
        valueListenable: _selectedStation,
        builder: (context, selectedStation, child) {
          if (hasDirection) {
            return CustomDragableWidget(
              scrollController: sheetScrollController,
              childrens: [
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
                            context
                                .read<TruckNavigationCubit>()
                                .calculateRoute();
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
              ],
            );
          } else if (hasTapDirection) {
            return CustomDragableWidget(
              scrollController: sheetScrollController,
              initialSize: 0.34,
              childrens: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        context
                            .read<TruckNavigationCubit>()
                            .removeTapDestination();
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
                simpleTextTileWithIcon(AppImages.bookmarkIcon, 'Saved Place'),
                16.h,
                simpleTextTileWithIcon(
                  AppImages.blackWhitLocationIcon,
                  'Add New Place',
                ),
                32.h,
              ],
            );
          } else if (selectedStation != null) {
            return CustomDragableWidget(
              scrollController: sheetScrollController,
              childrens: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _selectedStation.value = null;
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
                    16.w,
                    Expanded(
                      child: SizedBox(
                        height: context.screenHeight * 0.042,
                        child: ListView.separated(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,

                          itemCount:
                              TruckNavigationStaticDetails.placeTypes.length,
                          separatorBuilder: (_, i) => 8.w,
                          itemBuilder: (_, i) => InkWell(
                            onTap: () {
                              _selectedStation.value =
                                  TruckNavigationStaticDetails.placeTypes[i];
                            },
                            child: HomeUtils.placeTypeChip(
                              TruckNavigationStaticDetails.placeTypes[i],
                              isSelected:
                                  selectedStation['name'] ==
                                  TruckNavigationStaticDetails
                                      .placeTypes[i]['name'],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                44.h,
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.screenWidth * 0.026,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      TruckNavigationStaticDetails.truckStops.length,
                      (i) => Column(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundImage: AssetImage(
                              TruckNavigationStaticDetails
                                      .truckStops[i]['icon'] ??
                                  '',
                            ),
                          ),
                          8.h,
                          Text(
                            TruckNavigationStaticDetails
                                    .truckStops[i]['name'] ??
                                '',
                            style: AppTextTheme().lightText.copyWith(
                              color: const Color(0xFF000301),
                              height: 1.40,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  //  SizedBox(
                  //   height: context.screenHeight * 0.065,
                  //   child: ListView.separated(
                  //     shrinkWrap: true,
                  //     scrollDirection: Axis.horizontal,

                  //     itemCount: TruckNavigationStaticDetails.truckStops.length,
                  //     separatorBuilder: (_, i) => 16.w,
                  //     itemBuilder: (_, i) => ,
                  //   ),
                  // ),
                ),
                40.h,
                DefaultTabController(
                  length: TruckNavigationStaticDetails.placeTypeTabOpt.length,
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
                                options: TruckNavigationStaticDetails
                                    .placeTypeTabOpt,
                              ),
                            ),
                            10.w,
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: const Color(0xffF5F7F9),
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    AppImages.filterIcon,
                                    height: 24,
                                    width: 24,
                                  ),
                                  Text(
                                    "Filter",
                                    style: AppTextTheme().bodyText.copyWith(
                                      color: AppColorTheme().secondary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        41.h,
                        SizedBox(
                          height: context.screenHeight * 0.6,
                          child: TabBarView(
                            children: [
                              ListView.builder(
                                physics: NeverScrollableScrollPhysics(),
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
                                    place: TruckNavigationStaticDetails
                                        .placesss[index],
                                    isSaved: true,
                                  ),
                                ),
                                itemCount: TruckNavigationStaticDetails
                                    .placesss
                                    .length,
                              ),
                              ListView.builder(
                                physics: NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) =>
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          searchTextEditController.text =
                                              TruckNavigationStaticDetails
                                                  .placess[index]
                                                  .address;
                                          place = TruckNavigationStaticDetails
                                              .placess[index];
                                        });
                                      },
                                      child: PlaceDisplayWidget(
                                        place: TruckNavigationStaticDetails
                                            .placess[index],
                                        isSaved: true,
                                      ),
                                    ),
                                itemCount:
                                    TruckNavigationStaticDetails.placess.length,
                              ),

                              ListView.builder(
                                physics: NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) =>
                                    PlaceDisplayWidget(
                                      place: TruckNavigationStaticDetails
                                          .terminals[index],
                                      isSaved: true,
                                    ),
                                itemCount: TruckNavigationStaticDetails
                                    .terminals
                                    .length,
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
          } else {
            return CustomDragableWidget(
              scrollController: sheetScrollController,
              childrens: [
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
                        onPressed: () => HomeUtils.openTripBottomSheet(
                          context,
                          onContinue: (destinationText) {
                            if ((destinationText ?? '').isNotEmpty) {
                              searchTextEditController.text =
                                  destinationText ?? "";
                            }
                            sheetScrollController.animateTo(
                              0.34,
                              duration: Durations.medium2,
                              curve: Curves.bounceIn,
                            );
                          },
                        ),
                        radius: 50,
                        icon: Icon(Icons.directions, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                15.h,
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
                15.h,
                if (!searchFieldFocusNode.hasFocus) ...[
                  currentLocationTile(context),
                  15.h,
                  DashedLine(color: Color(0xffEBEEF2)),
                  15.h,
                  GridView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
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
                  // Wrap(
                  //   children:

                  //    List.generate(
                  //     TruckNavigationStaticDetails.stationList.length,
                  //     (i) => Container(),
                  //   ),
                  // ),

                  // ListTile(
                  //   contentPadding: EdgeInsets.zero,
                  //   leading: CircleAvatar(
                  //     backgroundColor: Colors.transparent,
                  //     radius: 25,
                  //     child: SvgPicture.asset(AppIcons.weatherIcon),
                  //   ),
                  //   title: Text(
                  //     "24°C",
                  //     style: AppTextTheme().bodyText.copyWith(
                  //       color: Colors.black,
                  //       fontSize: 16,
                  //     ),
                  //   ),
                  //   subtitle: Row(
                  //     spacing: 4,
                  //     children: [
                  //       Icon(
                  //         Icons.warning_rounded,
                  //         size: 16,
                  //         color: Color(0xffFF4F5B),
                  //       ),
                  //       Expanded(
                  //         child: Text(
                  //           "The light rain next 2 hours",
                  //           style: AppTextTheme().lightText.copyWith(
                  //             color: AppColorTheme().secondary,
                  //           ),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  //   trailing: Icon(
                  //     Icons.arrow_forward_ios,
                  //     color: Colors.black,
                  //     size: 15,
                  //     weight: 30,
                  //   ),
                  // ),
                  // 15.h,
                  // DashedLine(color: Color(0xffEBEEF2)),
                  // 15.h,
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     Text(
                  //       "Nearby places",
                  //       style: AppTextTheme().headingText.copyWith(
                  //         fontSize: 16,
                  //       ),
                  //     ),
                  //     TextButton(
                  //       style: ButtonStyle(
                  //         visualDensity: VisualDensity(
                  //           vertical: -4.0,
                  //           horizontal: -4.0,
                  //         ),
                  //         padding: WidgetStatePropertyAll(EdgeInsets.zero),
                  //       ),
                  //       onPressed: () {
                  //         TruckNavigationUtils.openDialog(context);
                  //       },
                  //       child: Text(
                  //         "More",
                  //         style: AppTextTheme().bodyText.copyWith(
                  //           color: AppColorTheme().primary,
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  // 15.h,
                  // buildNearbyTruckStops(context),
                  // ...List.generate(TruckNavigationStaticDetails.places.length, (
                  //   index,
                  // ) {
                  //   final place = TruckNavigationStaticDetails.places[index];
                  //   return PlaceDisplayWidget(place: place);
                  // }),
                  // DashedLine(color: Color(0xffEBEEF2)),
                  // 15.h,
                  // Text(
                  //   "Quick Actions",
                  //   style: AppTextTheme().headingText.copyWith(fontSize: 16),
                  // ),
                  // 15.h,
                  // Container(
                  //   padding: EdgeInsets.symmetric(vertical: 7, horizontal: 10),
                  //   decoration: BoxDecoration(
                  //     borderRadius: BorderRadius.circular(10),
                  //     border: Border.all(color: Color(0xFFEBEEF2), width: 1),
                  //   ),
                  //   child: Row(
                  //     spacing: 5,
                  //     children: [
                  //       Icon(Icons.bookmark_sharp),
                  //       Expanded(
                  //         child: Text(
                  //           "Saved & recent places",
                  //           style: AppTextTheme().bodyText.copyWith(
                  //             fontSize: 16,
                  //           ),
                  //         ),
                  //       ),
                  //       Icon(
                  //         Icons.arrow_forward_ios,
                  //         color: Colors.black,
                  //         size: 15,
                  //         weight: 30,
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // 20.h,
                ],
                if (searchFieldFocusNode.hasFocus &&
                    searchTextEditController.text.isEmpty) ...[
                  15.h,
                  // InkWell(
                  //   onTap: () {
                  //     TruckNavigationUtils.openDialog(context);
                  //   },
                  //   child: Row(
                  //     children: [
                  //       Icon(
                  //         Icons.location_on,
                  //         color: AppColorTheme().primary,
                  //       ),
                  //       12.w,

                  //       Text(
                  //         'Add a missing place to Ommo.',
                  //         style: TextStyle(
                  //           color: AppColorTheme().primary,
                  //           fontSize: 16,
                  //           fontWeight: FontWeight.w600,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  CustomTabBarWidget(
                    options: TruckNavigationStaticDetails.locationOpt,
                    tabController: _tabController,
                  ),

                  15.h,
                  // ListView(
                  //   shrinkWrap: true,
                  //   padding: EdgeInsets.zero,
                  //   physics: NeverScrollableScrollPhysics(),
                  //   children: [
                  //     ListTile(
                  //       contentPadding: EdgeInsets.zero,
                  //       leading: CircleAvatar(
                  //         radius: 25,
                  //         backgroundColor: AppColorTheme().primary
                  //             .withValues(alpha: 0.2),
                  //         child: SvgPicture.asset(
                  //           AppIcons.navigationIconGreen,
                  //         ),
                  //       ),
                  //       title: Text(
                  //         "My location",
                  //         style: AppTextTheme().bodyText.copyWith(
                  //           fontSize: 16,
                  //         ),
                  //       ),
                  //     ),
                  //     ...List.generate(
                  //       4,
                  //       (index) => ListTile(
                  //         contentPadding: EdgeInsets.zero,
                  //         leading: CircleAvatar(
                  //           radius: 25,
                  //           backgroundColor: Color(0xffF4F6F8),
                  //           child: SvgPicture.asset(AppIcons.frameIcon),
                  //         ),
                  //         title: Text(
                  //           "1600 Amphitheatre Parkway",
                  //           style: AppTextTheme().bodyText.copyWith(
                  //             fontSize: 16,
                  //           ),
                  //         ),
                  //         subtitle: Text(
                  //           "Manhattan, New York, NY, USA",
                  //           style: AppTextTheme().lightText.copyWith(
                  //             color: AppColorTheme().secondary,
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
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
                            sheetScrollController.animateTo(
                              0.34,
                              duration: Durations.medium2,
                              curve: Curves.bounceIn,
                            );
                          },
                        ),
                        // ListView(
                        //   shrinkWrap: true,
                        //   padding: EdgeInsets.zero,
                        //   physics: NeverScrollableScrollPhysics(),
                        //   children: [

                        //     ...List.generate(
                        //       4,
                        //       (index) => ListTile(
                        //         contentPadding: EdgeInsets.zero,
                        //         leading: CircleAvatar(
                        //           radius: 25,
                        //           backgroundColor: Color(0xffF4F6F8),
                        //           child: SvgPicture.asset(AppIcons.frameIcon),
                        //         ),
                        //         title: Text(
                        //           "1600 Amphitheatre Parkway",
                        //           style: AppTextTheme().bodyText.copyWith(
                        //             fontSize: 16,
                        //           ),
                        //         ),
                        //         subtitle: Text(
                        //           "Manhattan, New York, NY, USA",
                        //           style: AppTextTheme().lightText.copyWith(
                        //             color: AppColorTheme().secondary,
                        //           ),
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) => GestureDetector(
                            onTap: () {
                              setState(() {
                                searchTextEditController.text =
                                    TruckNavigationStaticDetails
                                        .placess[index]
                                        .address;
                                place =
                                    TruckNavigationStaticDetails.placess[index];
                              });
                            },
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
                                              .setDestinationCoordinate(item);
                                          context
                                              .read<RecentSearchCubit>()
                                              .addSearchFromPlace(item.place!);

                                          // context
                                          //     .read<TruckNavigationCubit>()
                                          //     .confirmDestination();

                                          sheetScrollController.animateTo(
                                            0.34,
                                            duration: Durations.medium2,
                                            curve: Curves.bounceIn,
                                          );
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
                                        // leading: CircleAvatar(
                                        //   radius: 25,
                                        //   backgroundColor: AppColorTheme()
                                        //       .primary
                                        //       .withValues(alpha: 0.2),
                                        //   child: SvgPicture.asset(
                                        //     AppIcons.navigationIconGreen,
                                        //   ),
                                        // ),
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

                if (searchFieldFocusNode.hasFocus &&
                    searchTextEditController.text.isNotEmpty &&
                    place != null) ...[
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
                    title: Text(
                      place!.title,
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
                        CustomRatingIndicator(rating: 5.0),
                        Text(
                          place!.rating.toString(),
                          style: AppTextTheme().lightText.copyWith(
                            color: Color(0xffFF8800),
                          ),
                        ),
                        Text(
                          "(${place!.reviewCount})  • ${place!.storeType} • ${place!.distance} mi",
                          style: AppTextTheme().lightText.copyWith(
                            color: AppColorTheme().secondary,
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
                        child: Container(
                          alignment: Alignment.center,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(50),
                              right: Radius.circular(50),
                            ),
                            border: Border.all(color: Color(0xffEBEEF2)),
                          ),
                          child: Row(
                            spacing: 5,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bookmark_border_outlined,
                                color: Colors.black,
                                size: 20,
                              ),
                              Text(
                                "Save",
                                style: AppTextTheme().bodyText.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(50),
                              right: Radius.circular(50),
                            ),
                            border: Border.all(color: Color(0xffEBEEF2)),
                          ),
                          child: Row(
                            spacing: 5,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                color: Colors.black,
                                size: 20,
                              ),
                              Text(
                                "Save",
                                style: AppTextTheme().bodyText.copyWith(
                                  fontSize: 16,
                                ),
                              ),
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
                    leading: Icon(
                      Icons.location_on_outlined,
                      color: Colors.black,
                    ),
                    horizontalTitleGap: 5,
                    title: Text(
                      place!.address,
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
                            text: place!.shopStatus == true
                                ? "Opened"
                                : "Closed",
                            style: AppTextTheme().lightText.copyWith(
                              fontSize: 16,
                              color: place!.shopStatus == true
                                  ? AppColorTheme().primary
                                  : Colors.red,
                            ),
                          ),
                          TextSpan(
                            text: "  •  ", // example extra text
                            style: AppTextTheme().lightText.copyWith(
                              fontSize: 16,
                              color: AppColorTheme().secondary,
                            ),
                          ),
                          TextSpan(
                            text: place!.shopStatus != true
                                ? "Opens at ${place!.time}"
                                : "Closes at ${place!.time}",
                          ),
                        ],
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.phone_outlined, color: Colors.black),
                    horizontalTitleGap: 5,
                    title: Text(
                      "(406) 555-0120 ",
                      style: AppTextTheme().lightText.copyWith(fontSize: 16),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.language, color: Colors.black),
                    horizontalTitleGap: 5,
                    title: Text(
                      "https://www.elizabeth-restaurant.com",
                      style: AppTextTheme().lightText.copyWith(fontSize: 16),
                    ),
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
                  DashedLine(),
                  20.h,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Q&As",
                        style: AppTextTheme().headingText.copyWith(
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        style: ButtonStyle(
                          padding: WidgetStatePropertyAll(EdgeInsets.zero),
                          visualDensity: VisualDensity(
                            horizontal: -4.0,
                            vertical: -4.0,
                          ),
                        ),
                        onPressed: () {},
                        child: Text(
                          "More",
                          style: AppTextTheme().headingText.copyWith(
                            fontSize: 16,
                            color: AppColorTheme().primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  20.h,
                  ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
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
                                Text(
                                  "Does Walmart allow overnight truck parking?",
                                  style: AppTextTheme().bodyText.copyWith(
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  "Some locations do, but always check with the store first.",
                                  style: AppTextTheme().lightText.copyWith(
                                    color: AppColorTheme().secondary,
                                  ),
                                ),
                                Row(
                                  spacing: 8,
                                  children: [
                                    Text(
                                      "View 7 replies",
                                      style: AppTextTheme().bodyText.copyWith(
                                        color: AppColorTheme().primary,
                                      ),
                                    ),
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
                          suffixIcon: CircleAvatar(
                            backgroundColor: AppColorTheme().primary,
                            child: Icon(Icons.arrow_upward, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  20.h,
                  DashedLine(),
                  20.h,
                  Text(
                    "How was your experience here?",
                    style: AppTextTheme().bodyText.copyWith(
                      fontSize: 16,
                      fontWeight: AppFontWeight.semiBold,
                    ),
                  ),
                  20.h,
                  RatingBar.builder(
                    itemPadding: EdgeInsets.all(3),
                    unratedColor: Color(0xffEBEEF2),
                    itemBuilder: (context, index) =>
                        SvgPicture.asset(AppIcons.ratingIcon),
                    onRatingUpdate: (rating) {},
                  ),
                ],
              ],
            );
          }
        },
      ),
    ];
  }

  List<Widget> buildNavigationUi(TruckNavigationState state) {
    return [
      MapView(),
      BlocBuilder<TruckNavigationCubit, TruckNavigationState>(
        buildWhen: (p, c) => p.maneuverProgress != c.maneuverProgress,
        builder: (context, state) =>
            (state.currentRoute == null || state.maneuverProgress == null)
            ? SizedBox()
            : Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: Container(
                  height: 150,
                  padding: EdgeInsets.all(16),
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
                  child: Column(
                    spacing: 10,
                    children: [
                      Row(
                        spacing: 10,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColorTheme().primary,
                            child: Icon(
                              state.currentRoute?.maneuverInstructionIcon(
                                state.maneuverProgress?.maneuverIndex,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.currentRoute
                                          ?.formattedManeuverInstructionWithRemainingDistance(
                                            state
                                                .maneuverProgress
                                                ?.maneuverIndex,
                                            state
                                                .maneuverProgress
                                                ?.remainingDistanceInMeters
                                                .toDouble(),
                                          ) ??
                                      '',
                                  style: AppTextTheme().subHeadingText2
                                      .copyWith(fontSize: 16),
                                ),
                                Text(
                                  state.currentRoute?.maneuverNextAddress(
                                        state.maneuverProgress?.maneuverIndex,
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
                      DashedLine(),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColorTheme().whiteShade,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: List.generate(4, (index) {
                              return Expanded(
                                child: Icon(
                                  _setDirectionIcon(index),
                                  color: AppColorTheme().secondary,
                                  size: 30,
                                  weight: 1.5,
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),

      Positioned(
        bottom: 250,
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
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: Text(
                        "50",
                        style: AppTextTheme().subHeadingText.copyWith(
                          fontSize: 28,
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
                            "5",
                            style: AppTextTheme().subHeadingText.copyWith(
                              fontSize: 28,
                            ),
                          ),
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

      Positioned(
        bottom: 250,
        right: 20,
        child: Row(
          children: [
            InkWell(
              onTap: () =>
                  context.read<TruckNavigationCubit>().toggleCameraControll(),
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
                child: BlocBuilder<TruckNavigationCubit, TruckNavigationState>(
                  buildWhen: (p, c) =>
                      p.cameraControlledByNavigator !=
                      c.cameraControlledByNavigator,
                  builder: (context, state) {
                    if (state.cameraControlledByNavigator) {
                      return Icon(
                        Icons.pan_tool_rounded,
                        color: Colors.black,
                        size: 20,
                      );
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
      ),

      CustomDragableWidget(
        initialSize: 0.24,
        bottomWidget: Padding(
          padding: EdgeInsets.all(20),
          child: CustomButtonWidget(
            bgColor: AppColorTheme().red2,
            textColor: Colors.white,
            icon: Icon(Icons.double_arrow, color: Colors.white, size: 18),
            isRightSide: true,
            title: "End Trip",
            onPressed: () {
              context.read<TruckNavigationCubit>().stopNavigation();
              searchTextEditController.clear();
              TruckNavigationUtils.saveDialog(context);
            },
          ),
        ),
        childrens: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            spacing: 10,
            children: [
              Image.asset('assets/images/Icon (30).png', width: 48, height: 48),
              Expanded(
                child: Column(
                  spacing: 2,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.hasTapDestination
                          ? (state.hasdestinationFromRecent
                                    ? state
                                          .destinationFromRecent
                                          ?.formattedTitle
                                    : state
                                          .tappedPlace
                                          ?.data
                                          ?.formattedTitle) ??
                                ''
                          : state.selectedSuggestion?.place?.formattedTitle ??
                                '',
                      style: AppTextTheme().subHeadingText.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      state.hasTapDestination
                          ? (state.hasdestinationFromRecent
                                    ? state
                                          .destinationFromRecent
                                          ?.formattedSubTitle
                                    : state
                                          .tappedPlace
                                          ?.data
                                          ?.formattedSubtitle) ??
                                ''
                          : state
                                    .selectedSuggestion
                                    ?.place
                                    ?.formattedSubtitle ??
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

              // GestureDetector(
              //   onTap: () {
              //     // cancelNavigation();
              //   },
              //   child: CircleAvatar(
              //     radius: 25,
              //     backgroundColor: AppColorTheme().whiteShade,
              //     child: const Icon(
              //       Icons.arrow_back_ios,
              //       color: Colors.black,
              //       size: 18,
              //     ),
              //   ),
              // ),
            ],
          ),
          20.h,
          DashedLine(),
          20.h,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,

                children: [
                  Text(
                    state.currentRoute?.formattedETA(context) ?? '',
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
                    state.currentRoute?.formattedDuration ?? '',
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
                    state.currentRoute?.distanceInMilesINNumber ?? '',
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
                      : state.selectedSuggestion?.place?.address.addressText ??
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
      ),
    ];
  }

  Widget _styleButton(String label, MapScheme scheme, String icon, int index) {
    return ValueListenableBuilder(
      valueListenable: selectIndexMapView,
      builder: (_, v, c) {
        bool isSelect = v == index;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              context.read<TruckNavigationCubit>().changeMapScheme(scheme);
              selectIndexMapView.value = index;
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
                  context.read<TruckNavigationCubit>().calculateRoute();
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
                    context.read<TruckNavigationCubit>().calculateRoute();
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

  Widget buildNearbyTruckStops(BuildContext context) {
    return BlocBuilder<TruckNavigationCubit, TruckNavigationState>(
      buildWhen: (p, c) => p.nearbyTruckStops != c.nearbyTruckStops,
      builder: (context, state) => FutureDataBuilder(
        future: state.nearbyTruckStops,
        onSuccess: (places) => Column(
          children: List.generate(
            places?.length ?? 0,
            (index) =>
                PlaceDisplayWidget(place: places?[index].toPlaceDataModel),
          ),
        ),
        loader: Column(
          spacing: 10,
          children: List.generate(
            3,
            (i) => ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(10),
              child: Shimmer(
                color: Colors.greenAccent,
                child: SizedBox(width: double.infinity, height: 80),
              ),
            ),
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
  const PlaceDisplayWidget({super.key, this.place, this.isSaved = false});

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
