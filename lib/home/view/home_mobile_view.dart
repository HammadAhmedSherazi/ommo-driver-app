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
import 'package:ommo/home/view/truck_navigation/cubit/truck_navigation_cubit.dart';
import 'package:ommo/home/view/truck_navigation/cubit/truck_navigation_state.dart';
import 'package:ommo/home/view/truck_navigation/truck_navigation_static_details.dart';
import 'package:ommo/home/view/truck_navigation/truck_navigation_utils.dart';
import 'package:ommo/utils/extension/route_extension.dart';
import 'package:ommo/utils/utils.dart';
import '../home.dart';

class HomeMobileView extends StatefulWidget {
  const HomeMobileView({super.key});

  @override
  State<HomeMobileView> createState() => _HomeMobileViewState();
}

class _HomeMobileViewState extends State<HomeMobileView> with SingleTickerProviderStateMixin {
  final TextEditingController searchTextEditController = TextEditingController();
  FocusNode searchFieldFocusNode = FocusNode();
  late final TabController _tabController;
  final List<TextEditingController> textController = [TextEditingController(text: "Start My Current Location")];
  final List<FocusNode> focusNode = [FocusNode()];
  bool showMore = false, changeMapScheme = false;
  int selectIndexMapView = 0;
  PlaceDataModel? place;
  int selectLocationOpt = 0;
  // bool isSetDirection = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: TruckNavigationStaticDetails.locationOpt.length, vsync: this);
    textController.add(searchTextEditController);
    focusNode.add(FocusNode());
    searchFieldFocusNode.addListener(() {
      setState(() {});
    });
  }

  void startNavigation() {}

  void cancelNavigation() {
    //  openRouteDialogSheet();
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
      body: BlocBuilder<TruckNavigationCubit, TruckNavigationState>(
        buildWhen: (previous, current) => previous.currentRoute != current.currentRoute,
        builder: (context, state) {
          return Stack(children: !state.isNavigating ? buildInitialUi(context, state.hasDirection) : buildNavigationUi());
        },
      ),
    );
  }

  List<Widget> buildInitialUi(BuildContext context, bool hasDirection) {
    return [
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
              children: List.generate(TruckNavigationStaticDetails.mapSchemes.length, (index) {
                final item = TruckNavigationStaticDetails.mapSchemes[index];
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
          itemCount: TruckNavigationStaticDetails.stationList.length,
          padding: EdgeInsets.symmetric(horizontal: AppTheme.horizontalPadding),
          separatorBuilder: (context, index) => 5.w,
          itemBuilder: (context, index) => GestureDetector(
            onTap: () {
              // _hereMapController?.mapScene.enableFeatures({MapFeatures.lowSpeedZones: MapFeatureModes.lowSpeedZonesAll});
              // _truckGuidanceExample = TruckGuidanceExample(_showDialog, _hereMapController!);
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
                    child: Text(
                      TruckNavigationStaticDetails.stationList[index].splitMapJoin('')[0],
                      style: AppTextTheme().headingText.copyWith(fontSize: 16),
                    ),
                  ),
                  Text(TruckNavigationStaticDetails.stationList[index], style: AppTextTheme().bodyText),
                ],
              ),
            ),
          ),
          scrollDirection: Axis.horizontal,
        ),
        // width: double.infinity,
      ),

      CustomDragableWidget(
        childrens: hasDirection
            ? [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Create a trip", style: AppTextTheme().subHeadingText.copyWith(fontWeight: AppFontWeight.semiBold, fontSize: 20)),

                    IconButton(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity(horizontal: -4.0, vertical: -4.0),
                      onPressed: () {
                        // setState(() {
                        //   hasDirection = false;
                        // });
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
                        TruckNavigationUtils.openSettingBottomSheet(context);
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
                    TruckNavigationStaticDetails.settingChipsList.length,
                    (index) => Chip(
                      deleteIconColor: AppColorTheme().secondary,
                      onDeleted: () {
                        setState(() {
                          TruckNavigationStaticDetails.settingChipsList.removeAt(index);
                        });
                      },
                      deleteIconBoxConstraints: BoxConstraints(maxHeight: 24, maxWidth: 24),
                      padding: EdgeInsets.symmetric(vertical: 0, horizontal: 3),
                      backgroundColor: Color(0xffF4F6F8),
                      deleteIcon: Icon(Icons.cancel),

                      label: Text(TruckNavigationStaticDetails.settingChipsList[index]),
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
                Text("Available routes", style: AppTextTheme().subHeadingText.copyWith(fontSize: 16)),
                BlocBuilder<TruckNavigationCubit, TruckNavigationState>(
                  buildWhen: (p, c) => p.currentRoute != c.currentRoute,
                  builder: (context, state) {
                    return ListTile(
                      // minLeadingWidth: 20,
                      onTap: () {
                        TruckNavigationUtils.openRouteDialogSheet(context, textController.last.text);
                        // if (state.availableDestinationRoutes?[index] != null) {
                        //   _truckGuidanceExample?.selectRouteAndDrawPolyLines(state.availableDestinationRoutes![index]);
                        // }
                      },
                      contentPadding: EdgeInsets.symmetric(vertical: 5),
                      leading: CircleAvatar(radius: 25, backgroundColor: Color(0xffF4F6F8), child: SvgPicture.asset(AppIcons.truckIcon)),
                      title: Text(
                        // "Via I-20E",
                        // "Route",
                        state.currentRoute?.getRouteName ?? '',
                        style: AppTextTheme().bodyText.copyWith(fontSize: 16),
                      ),
                      subtitle: (state.currentRoute?.hasTolls ?? false)
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
                                state.currentRoute?.formattedDuration ?? '',
                                // "2h 11m",
                                style: AppTextTheme().lightText.copyWith(color: AppColorTheme().primary),
                              ),
                              Text(
                                state.currentRoute?.distanceInMiles ?? '',
                                //  "145 mi",
                                style: AppTextTheme().lightText.copyWith(color: AppColorTheme().secondary),
                              ),
                            ],
                          ),
                          Icon(Icons.directions, color: Colors.black, size: 20),
                        ],
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
              ]
            : [
                CustomTextfieldWidget(
                  focusNode: searchFieldFocusNode,
                  onTapOutside: (e) {},
                  onChanged: (text) {
                    // setState(() {});
                    Future.delayed(Duration(milliseconds: 400), () {
                      if (context.mounted) {
                        context.read<TruckNavigationCubit>().searchPlaces(text);
                        // context.read<MapCubit>().searchLocation(text, TruckGuidanceExample.myStartCoordinadtes);
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
                      // setState(() {
                      //   isSetDirection = true;
                      // });

                      context.read<TruckNavigationCubit>().calculateRoute();
                      // context.read<MapCubit>().setRoute();
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
                          child: Text("The light rain next 2 hours", style: AppTextTheme().lightText.copyWith(color: AppColorTheme().secondary)),
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
                          TruckNavigationUtils.openDialog(context);
                        },
                        child: Text("More", style: AppTextTheme().bodyText.copyWith(color: AppColorTheme().primary)),
                      ),
                    ],
                  ),
                  15.h,
                  ...List.generate(TruckNavigationStaticDetails.places.length, (index) {
                    final place = TruckNavigationStaticDetails.places[index];
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

                  CustomTabBarWidget(options: TruckNavigationStaticDetails.locationOpt, tabController: _tabController),
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
                                leading: CircleAvatar(radius: 25, backgroundColor: Color(0xffF4F6F8), child: SvgPicture.asset(AppIcons.frameIcon)),
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
                                searchTextEditController.text = TruckNavigationStaticDetails.places[index].address;
                                place = TruckNavigationStaticDetails.places[index];
                              });
                            },
                            child: PlaceDisplayWidget(place: TruckNavigationStaticDetails.places[index], isSaved: true),
                          ),
                          itemCount: TruckNavigationStaticDetails.places.length,
                        ),
                        ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) => PlaceDisplayWidget(place: TruckNavigationStaticDetails.terminals[index], isSaved: true),
                          itemCount: TruckNavigationStaticDetails.terminals.length,
                        ),
                      ],
                    ),
                  ),
                ],

                if (searchFieldFocusNode.hasFocus && searchTextEditController.text.isNotEmpty) ...[
                  BlocBuilder<TruckNavigationCubit, TruckNavigationState>(
                    buildWhen: (previous, current) {
                      return previous.destinationSuggestions?.data != current.destinationSuggestions?.data;
                    },
                    builder: (context, state) {
                      return (state.destinationSuggestions?.data ?? []).isNotEmpty
                          ? ListView.separated(
                              itemBuilder: (context, index) {
                                final Suggestion? item = state.destinationSuggestions?.data?[index];

                                return item == null
                                    ? SizedBox()
                                    : ListTile(
                                        onTap: () {
                                          searchTextEditController.text = item.title;
                                          context.read<TruckNavigationCubit>().setDestinationCoordinate(item.place!.geoCoordinates!);
                                          // context.read<MapCubit>().setDestinationCoordinate(item.place!.geoCoordinates!);
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
                              itemCount: state.destinationSuggestions?.data?.length ?? 0,
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
                  Text("How was your experience here?", style: AppTextTheme().bodyText.copyWith(fontSize: 16, fontWeight: AppFontWeight.semiBold)),
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
    ];
  }

  List<Widget> buildNavigationUi() {
    return [
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
              // context.read<MapCubit>().startNavigation();

              TruckNavigationUtils.saveDialog(context);
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
                      Expanded(child: Text("Keep right to merge onto Lincoln Tunnel", style: AppTextTheme().lightText.copyWith(fontSize: 16))),
                    ],
                  ),
                  Row(
                    spacing: 10,
                    children: [
                      Icon(Icons.warning_rounded, color: Color(0xffFF4F5B)),
                      Expanded(
                        child: Text("Toll required at Lincoln Tunnel", style: AppTextTheme().bodyText.copyWith(color: AppColorTheme().secondary)),
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
                      Expanded(child: Text("Keep right to merge onto Lincoln Tunnel", style: AppTextTheme().lightText.copyWith(fontSize: 16))),
                    ],
                  ),
                  Row(
                    spacing: 10,
                    children: [
                      Icon(Icons.warning_rounded, color: Color(0xffFF4F5B)),
                      Expanded(
                        child: Text("Toll required at Lincoln Tunnel", style: AppTextTheme().bodyText.copyWith(color: AppColorTheme().secondary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ];
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
