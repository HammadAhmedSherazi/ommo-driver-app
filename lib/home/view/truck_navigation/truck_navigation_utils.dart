import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:here_sdk/mapview.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ommo/custom_widget/custom_accordion_widget.dart';
import 'package:ommo/custom_widget/custom_widget.dart';
import 'package:ommo/home/view/edit_truck_specifications_view.dart';
import 'package:ommo/home/view/home_mobile_view.dart';
import 'package:ommo/logic/cubit/truck_navigation/truck_navigation_cubit.dart';
import 'package:ommo/logic/cubit/truck_navigation/truck_navigation_state.dart';
import 'package:ommo/home/view/truck_navigation/truck_navigation_static_details.dart';
import 'package:ommo/logic/cubit/truck_specifications/truck_specification_cubit.dart';
import 'package:ommo/logic/cubit/truck_specifications/truck_specifications_state.dart';
import 'package:ommo/utils/extension/manuever_extension.dart';
import 'package:ommo/utils/extension/route_extension.dart';
import 'package:ommo/utils/extension/section_extension.dart';
import 'package:ommo/utils/utils.dart';
import 'package:here_sdk/routing.dart' as r;

class TruckNavigationUtils {
  static void openDialog(BuildContext context) {
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
    bool showMore = false;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                              Text(
                                "Add a place",
                                style: AppTextTheme().headingText,
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity(
                                  horizontal: -4.0,
                                  vertical: -4.0,
                                ),
                                onPressed: () {
                                  context.popPage();
                                },
                                icon: Icon(
                                  Icons.close,
                                  color: Color(0xff8C93A4),
                                ),
                              ),
                            ],
                          ),
                          24.h,
                          Text(
                            "Name",
                            style: AppTextTheme().bodyText.copyWith(
                              fontSize: 16,
                            ),
                          ),
                          7.h,
                          CustomTextfieldWidget(hintText: "Enter place name"),
                          24.h,
                          Text(
                            "Address",
                            style: AppTextTheme().bodyText.copyWith(
                              fontSize: 16,
                            ),
                          ),
                          7.h,
                          CustomTextfieldWidget(
                            hintText: "Enter address",
                            suffixIcon: SvgPicture.asset(
                              AppIcons.navigationOutlineIcon,
                            ),
                          ),
                          24.h,
                          SizedBox(
                            height: 200,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              // child: MapView(),
                              child: HereMap(
                                // onMapCreated: (mapController) {
                                //   // Load the map scene using a map scheme to render the map with.
                                //   mapController.mapScene.loadSceneForMapScheme(MapScheme.normalDay, (MapError? error) {
                                //     if (error == null) {
                                //       mapController.mapScene.enableFeatures({MapFeatures.lowSpeedZones: MapFeatureModes.lowSpeedZonesAll});
                                //       // _truckGuidanceExample =
                                //       //     TruckGuidanceExample(_showDialog, hereMapController);
                                //       // _truckGuidanceExample!.setUICallback(this);
                                //     } else {}
                                //   }
                                //   );
                                // },
                              ),
                            ),
                          ),
                          if (showMore) ...[
                            24.h,
                            Text(
                              "Phone number",
                              style: AppTextTheme().bodyText.copyWith(
                                fontSize: 16,
                              ),
                            ),
                            7.h,
                            CustomTextfieldWidget(
                              hintText: "Enter number",
                              keyboardType: TextInputType.phone,
                            ),
                            24.h,
                            Text(
                              "Website",
                              style: AppTextTheme().bodyText.copyWith(
                                fontSize: 16,
                              ),
                            ),
                            7.h,
                            CustomTextfieldWidget(
                              hintText: "Paste link",
                              keyboardType: TextInputType.phone,
                            ),
                            24.h,
                            Text(
                              "Opening hours",
                              style: AppTextTheme().bodyText.copyWith(
                                fontSize: 16,
                              ),
                            ),
                            7.h,
                            CustomTextfieldWidget(
                              suffixIcon: Icon(
                                Icons.arrow_forward_ios,
                                size: 17,
                              ),
                              hintText: "Opening hours ",
                              onTap: () {
                                openHourDialog(context);
                              },
                            ),
                            24.h,
                            Text(
                              "Brand logo (optional)",
                              style: AppTextTheme().bodyText.copyWith(
                                fontSize: 16,
                              ),
                            ),
                            7.h,
                            GestureDetector(
                              onTap: () async {
                                final picker = ImagePicker();

                                // Show choice dialog
                                final source =
                                    await showModalBottomSheet<ImageSource>(
                                      context: context,
                                      builder: (context) {
                                        return SafeArea(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical:
                                                  AppTheme.horizontalPadding,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                ListTile(
                                                  leading: const Icon(
                                                    Icons.camera_alt,
                                                  ),
                                                  title: const Text(
                                                    'Take a photo',
                                                  ),
                                                  onTap: () => Navigator.pop(
                                                    context,
                                                    ImageSource.camera,
                                                  ),
                                                ),
                                                ListTile(
                                                  leading: const Icon(
                                                    Icons.photo_library,
                                                  ),
                                                  title: const Text(
                                                    'Choose from gallery',
                                                  ),
                                                  onTap: () => Navigator.pop(
                                                    context,
                                                    ImageSource.gallery,
                                                  ),
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
                                final picked = await picker.pickImage(
                                  source: source,
                                );
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
                                        Text(
                                          "Add Logo",
                                          style: AppTextTheme().bodyText
                                              .copyWith(
                                                color: AppColorTheme().primary,
                                              ),
                                        ),
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
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                            image: DecorationImage(
                                              image: FileImage(
                                                File(selectedImage!.path),
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
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
                                                  child: Icon(
                                                    Icons.close,
                                                    size: 10,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            24.h,
                            Text(
                              "Amenities",
                              style: AppTextTheme().bodyText.copyWith(
                                fontSize: 16,
                              ),
                            ),
                            7.h,
                            ...List.generate(
                              amenitiesList.length,
                              (index) => Row(
                                children: [
                                  Transform.scale(
                                    scale: 0.6,
                                    child: Switch.adaptive(
                                      padding: EdgeInsets.zero,

                                      value: amenitiesList.entries
                                          .elementAt(index)
                                          .value,
                                      onChanged: (v) {
                                        setState(() {
                                          amenitiesList.update(
                                            amenitiesList.entries
                                                .elementAt(index)
                                                .key,
                                            (bol) => !bol,
                                          );
                                        });
                                      },
                                    ),
                                  ),
                                  Text(
                                    amenitiesList.entries.elementAt(index).key,
                                    style: AppTextTheme().bodyText,
                                  ),
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
                                  Text(
                                    "Add more details",
                                    style: AppTextTheme().bodyText.copyWith(
                                      color: AppColorTheme().primary,
                                    ),
                                  ),
                                  Icon(Icons.keyboard_arrow_down, size: 17),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsetsGeometry.all(
                        AppTheme.horizontalPadding,
                      ),
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

  static void openHourDialog(BuildContext context) {
    Map<String, bool> days = {
      "Monday": false,
      "Tuesday": false,
      "Wednesday": false,
      "Thursday": false,
      "Friday": false,
      "Saturday": true,
      "Sunday": true,
    };

    List<TextEditingController> openTextEditController = List.generate(
      days.length,
      (index) => TextEditingController(),
    );

    List<TextEditingController> closeTextEditController = List.generate(
      days.length,
      (index) => TextEditingController(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: Colors.black,
                                ),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity(
                                  horizontal: -4.0,
                                  vertical: -4.0,
                                ),
                              ),
                              Text(
                                "Opening hours",
                                style: AppTextTheme().headingText,
                              ),
                              IconButton(
                                onPressed: () => context.popPage(),
                                icon: Icon(
                                  Icons.close,
                                  color: Color(0xff8C93A4),
                                ),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity(
                                  horizontal: -4.0,
                                  vertical: -4.0,
                                ),
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
                                    Text(
                                      dayName,
                                      style: AppTextTheme().bodyText,
                                    ),
                                    Spacer(),
                                    Text(
                                      "Closed",
                                      style: AppTextTheme().lightText,
                                    ),
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

                                        controller:
                                            openTextEditController[index],
                                        onTap: () async {
                                          final TimeOfDay? picked =
                                              await showTimePicker(
                                                context: context,
                                                initialTime: TimeOfDay.now(),
                                              );
                                          if (!context.mounted) return;
                                          if (picked != null) {
                                            openTextEditController[index].text =
                                                picked.format(context);
                                          }
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    Expanded(
                                      child: CustomTextfieldWidget(
                                        hintText: "--:--",

                                        controller:
                                            closeTextEditController[index],
                                        onTap: () async {
                                          final TimeOfDay? picked =
                                              await showTimePicker(
                                                context: context,
                                                initialTime: TimeOfDay.now(),
                                              );
                                          if (!context.mounted) return;
                                          if (picked != null) {
                                            closeTextEditController[index]
                                                .text = picked.format(
                                              context,
                                            );
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

  static _setRestrictionIcon(String key) {
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

  static void openSettingBottomSheet(BuildContext context) {
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
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.horizontalPadding,
              ),
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
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.black,
                          size: 18,
                        ),
                      ),
                    ),
                    Text(
                      "Settings",
                      style: AppTextTheme().subHeadingText.copyWith(
                        fontWeight: AppFontWeight.semiBold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                20.h,
                DashedLine(),
                20.h,

                // Vehicle
                Text(
                  "Vehicle",
                  style: AppTextTheme().lightText.copyWith(
                    color: AppColorTheme().secondary,
                  ),
                ),
                20.h,
                ListTile(
                  onTap: () => Helpers.openBottomSheet(
                    context: context,
                    child: EditTruckSpecificationsView(),
                  ),
                  leading: SvgPicture.asset(AppIcons.localShippingIcon),
                  title: Text(
                    "My truck",
                    style: AppTextTheme().lightText.copyWith(fontSize: 16),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_outlined,
                    color: Colors.black,
                    size: 22,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),

                BlocBuilder<TruckSpecificationsCubit, TruckSpecificationState>(
                  builder: (context, state) => Column(
                    children: List.generate(
                      state.truckInfo.length,
                      (index) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: 20.w,
                        title: Text(
                          state.truckInfo.entries.elementAt(index).key,
                          style: AppTextTheme().lightText,
                        ),
                        visualDensity: const VisualDensity(vertical: -4.0),
                        trailing: Text(
                          state.truckInfo.entries.elementAt(index).value,
                          style: AppTextTheme().lightText.copyWith(
                            color: AppColorTheme().secondary,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ),
                  ),
                ),
                20.h,
                // Restrictions
                Text(
                  "Restrictions",
                  style: AppTextTheme().lightText.copyWith(
                    color: AppColorTheme().secondary,
                  ),
                ),
                20.h,
                ...List.generate(
                  TruckNavigationStaticDetails.routeRestriction.length,
                  (index) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: SvgPicture.asset(
                      _setRestrictionIcon(
                        TruckNavigationStaticDetails.routeRestriction.entries
                            .elementAt(index)
                            .key,
                      ),
                    ),
                    title: Text(
                      TruckNavigationStaticDetails.routeRestriction.entries
                          .elementAt(index)
                          .key,
                      style: AppTextTheme().lightText,
                    ),
                    visualDensity: const VisualDensity(vertical: -4.0),
                    trailing: Transform.scale(
                      scale: 0.6,
                      child: Switch.adaptive(
                        value: TruckNavigationStaticDetails
                            .routeRestriction
                            .entries
                            .elementAt(index)
                            .value,
                        onChanged: (v) {
                          setState(() {
                            TruckNavigationStaticDetails.routeRestriction
                                .update(
                                  TruckNavigationStaticDetails
                                      .routeRestriction
                                      .entries
                                      .elementAt(index)
                                      .key,
                                  (c) => v,
                                );
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

  static void openRouteDialogSheet(BuildContext context) {
    Helpers.openBottomSheet(
      context: context,
      child: BlocBuilder<TruckNavigationCubit, TruckNavigationState>(
        buildWhen: (p, c) => p.currentRoute != c.currentRoute,
        builder: (context, state) {
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
                              child: const Icon(
                                Icons.arrow_back_ios,
                                color: Colors.black,
                                size: 18,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                style: AppTextTheme().subHeadingText.copyWith(
                                  fontSize: 20,
                                ),
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text:
                                          state.currentRoute?.formattedDuration,
                                      // text: "2h 11m",
                                      style: TextStyle(
                                        color: AppColorTheme().primary,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          " (${state.currentRoute?.distanceInMiles ?? ''})",
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                state.currentRoute?.getRouteName ?? '',
                                style: AppTextTheme().lightText.copyWith(
                                  color: AppColorTheme().secondary,
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
                          Column(
                            spacing: 5,
                            children: [
                              Icon(Icons.circle_outlined, size: 18),
                              SizedBox(
                                height:
                                    30, // match with textfield height + spacing
                                child: CustomPaint(
                                  painter: DottedLinePainter(),
                                ),
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
                                Text(
                                  'My Current Location',
                                  style: AppTextTheme().bodyText.copyWith(
                                    fontSize: 16,
                                  ),
                                  maxLines: 2,
                                ),
                                TruckNavigationUtils.buildRouteDetails(
                                  state.currentRoute!,
                                ),
                                // Text("Times Square, New York, NY, USA", style: AppTextTheme().bodyText.copyWith(fontSize: 16), maxLines: 2),
                                // Row(
                                //   children: [
                                //     Icon(Icons.u_turn_right),
                                //     Text("20 min (25 mi)", style: AppTextTheme().lightText.copyWith(color: AppColorTheme().primary)),
                                //   ],
                                // ),
                                // Text("Centre St, Scranton, PA", style: AppTextTheme().bodyText.copyWith(fontSize: 16), maxLines: 2),
                                Text(
                                  state
                                          .selectedSuggestion
                                          ?.place
                                          ?.address
                                          .addressText ??
                                      '',
                                  style: AppTextTheme().bodyText.copyWith(
                                    fontSize: 16,
                                  ),
                                  maxLines: 2,
                                ),
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
                      context.popPage();
                      context.read<TruckNavigationCubit>().startNavigation();
                    },
                    icon: Icon(
                      Icons.double_arrow,
                      color: Colors.white,
                      size: 18,
                    ),
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

  static void saveDialog(BuildContext context) {
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColorTheme().primary.withValues(alpha: 0.2),
              ),
              child: Icon(Icons.bookmark_outline),
            ),
            Text(
              "Save this route ",
              style: AppTextTheme().headingText.copyWith(fontSize: 20),
            ),
            Text(
              "Would you like to save this route for future use?",
              style: AppTextTheme().lightText.copyWith(
                color: AppColorTheme().secondary,
              ),
              textAlign: TextAlign.center,
            ),
            CustomButtonWidget(
              title: "Yes",
              onPressed: () {
                context.popPage();
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

  static Widget buildRouteDetails(r.Route route) {
    return Column(
      children: List.generate(
        route.sections.length,
        (i) => buildSectionAccordion(route.sections[i]),
      ),
    );
  }

  static Widget buildSectionAccordion(r.Section section) {
    // Title: you can use road names from maneuvers or fallback
    final String title = section.maneuvers.isNotEmpty
        ? section.maneuvers.first.text
        : "Continue route";

    return CustomAccordionWidget(
      title: title,
      child: Padding(
        padding: const EdgeInsets.only(left: 40),
        child: Column(
          spacing: 10,
          children: [
            10.h,

            // ⏱ Section summary row
            Row(
              spacing: 10,
              children: [
                Text(
                  "${section.formattedDuration} (${section.distanceInMiles})",
                  style: AppTextTheme().bodyText.copyWith(
                    color: AppColorTheme().secondary,
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),

            // 🚘 All maneuvers inside this section
            for (final maneuver in section.maneuvers) ...[
              Row(
                spacing: 10,
                children: [
                  Icon(maneuver.toIcon, color: AppColorTheme().secondary),
                  Expanded(
                    child: Text(
                      maneuver.text, // "Turn left onto 9th Ave"
                      style: AppTextTheme().lightText.copyWith(fontSize: 16),
                    ),
                  ),
                ],
              ),
              if (maneuver.lengthInMeters > 0)
                Row(
                  spacing: 10,
                  children: [
                    24.w,
                    Text(
                      maneuver.formattedDistance,
                      style: AppTextTheme().bodyText.copyWith(
                        color: AppColorTheme().secondary,
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
            ],

            // ⚠️ Tolls if any
            for (final toll in section.tolls)
              Row(
                spacing: 10,
                children: [
                  const Icon(Icons.warning_rounded, color: Color(0xffFF4F5B)),
                  Expanded(
                    child: Text(
                      "Toll required ",
                      style: AppTextTheme().bodyText.copyWith(
                        color: AppColorTheme().secondary,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
