import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:here_sdk/search.dart';
import 'package:ommo/custom_widget/custom_widget.dart';
import 'package:ommo/home/view/home_mobile_view.dart';
import 'package:ommo/home/view/pick_location_from_map.dart';
import 'package:ommo/home/view/truck_navigation/truck_navigation_static_details.dart';
import 'package:ommo/logic/cubit/truck_navigation/truck_navigation_cubit.dart';
import 'package:ommo/logic/cubit/truck_navigation/truck_navigation_state.dart';
import 'package:ommo/services/hive/recent_search/cubit/recent_search_cubit.dart';
import 'package:ommo/services/hive/recent_search/cubit/recent_search_state.dart';
import 'package:ommo/services/hive/recent_search/model/recent_search_model.dart';
import 'package:ommo/utils/extension/place_extension.dart';
import 'package:ommo/utils/extension/recent_search_model_extension.dart';
import 'package:ommo/utils/generics/generics.dart';
import 'package:ommo/utils/helpers/helpers.dart';
import 'package:ommo/utils/constants/constants.dart';
import 'package:ommo/utils/theme/theme.dart';

class HomeUtils {
  static void openMoreTruckStopsBottomSheet(BuildContext context) {
    Helpers.openBottomSheet(
      context: context,
      child: SizedBox(
        height: context.screenHeight * 0.80,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.horizontalPadding),
          children: [
            Row(
              spacing: 10,
              children: [
                GestureDetector(
                  onTap: () {
                    context.popPage();
                    // if (onEditSuccess != null) onEditSuccess();
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
                  "More",
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
            Text(
              "Place Types",
              style: TextStyle(
                color: AppColorTheme().black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            16.h,
            Wrap(
              alignment: WrapAlignment.start,
              runAlignment: WrapAlignment.start,
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                TruckNavigationStaticDetails.placeTypes.length,
                (i) =>
                    placeTypeChip(TruckNavigationStaticDetails.placeTypes[i]),
              ),
            ),
            20.h,
            Text(
              "Repairs",
              style: TextStyle(
                color: AppColorTheme().black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            16.h,
            Wrap(
              alignment: WrapAlignment.start,
              runAlignment: WrapAlignment.start,
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                TruckNavigationStaticDetails.repairPlaces.length,
                (i) =>
                    placeTypeChip(TruckNavigationStaticDetails.repairPlaces[i]),
              ),
            ),
            20.h,
            Text(
              "Dealers",
              style: TextStyle(
                color: AppColorTheme().black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            16.h,
            Wrap(
              alignment: WrapAlignment.start,
              runAlignment: WrapAlignment.start,
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                TruckNavigationStaticDetails.dealers.length,
                (i) => placeTypeChip(TruckNavigationStaticDetails.dealers[i]),
              ),
            ),
            30.h,
          ],
        ),
      ),
    );
  }

  static placeTypeChip(Map data, {bool isSelected = false}) {
    return Container(
      // width: 100,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isSelected
              ? AppColorTheme().primary
              : const Color.fromRGBO(235, 238, 242, 1), // border color
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(data['icon'], height: 24, width: 24),
          Text(data['name'], style: AppTextTheme().bodyText),
          2.w,
        ],
      ),
    );
  }

  static void openTripBottomSheet(
    BuildContext context, {
    Function(String?)? onContinue,
  }) {
    final TextEditingController startController = TextEditingController(
      text: "Your Location",
    );
    final TextEditingController destinationController = TextEditingController();

    final FocusNode destinationFocusNode = FocusNode();
    ValueNotifier showRecentTab = ValueNotifier(true);

    // Auto-focus on destination field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      destinationFocusNode.requestFocus();
    });
    destinationController.addListener(() {
      if (destinationController.text.isNotEmpty && showRecentTab.value) {
        showRecentTab.value = false;
      } else if (destinationController.text.isEmpty && !showRecentTab.value) {
        showRecentTab.value = true;
      }
      Future.delayed(Duration(milliseconds: 400), () {
        if (context.mounted) {
          context.read<TruckNavigationCubit>().searchPlaces(
            destinationController.text,
          );
        }
      });
    });

    bool isLoading = false;

    Helpers.openBottomSheet(
      context: context,
      child: SizedBox(
        height: context.screenHeight * 0.9,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.horizontalPadding),
          child: Column(
            children: [
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
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.black),
                  ),
                ],
              ),
              20.h,
              VerticalStepWithTextField(
                textControllers: [startController, destinationController],
                focusNode: [FocusNode(), destinationFocusNode],
                removeFieldTap: () {},
                readOnly: [true, false],
              ),
              20.h,
              ValueListenableBuilder(
                valueListenable: showRecentTab,
                builder: (_, val, c) {
                  if (!val) {
                    return BlocConsumer<
                      TruckNavigationCubit,
                      TruckNavigationState
                    >(
                      listener: (context, state) {
                        if (state.currentRoute != null && state.hasDirection) {
                          isLoading = true;
                          Navigator.pop(context);
                        }
                      },
                      listenWhen: (previous, current) =>
                          previous.currentRoute != current.currentRoute,

                      buildWhen: (p, c) =>
                          p.destinationSuggestions != c.destinationSuggestions,
                      builder: (context, state) {
                        if (destinationController.text.isNotEmpty &&
                            (state.destinationSuggestions?.data ?? [])
                                .isNotEmpty) {
                          return ListView.separated(
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              final Suggestion? item =
                                  state.destinationSuggestions?.data?[index];
                              return item == null
                                  ? SizedBox()
                                  : ListTile(
                                      onTap: () {
                                        if (isLoading) return;

                                        context
                                            .read<RecentSearchCubit>()
                                            .addSearchFromPlace(item.place!);
                                        destinationController.text = item.title;

                                        context
                                            .read<TruckNavigationCubit>()
                                            .setDestinationCoordinate(item);

                                        if (destinationController
                                            .text
                                            .isNotEmpty) {
                                          if (onContinue != null) {
                                            onContinue(
                                              destinationController.text,
                                            );
                                          }
                                          isLoading = true;
                                          context
                                              .read<TruckNavigationCubit>()
                                              .calculateRoute();
                                        }
                                      },
                                      contentPadding: EdgeInsets.zero,
                                      leading: Column(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Color(0xffF4F6F8),
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
                                                  color:
                                                      AppColorTheme().secondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                      title: item.place
                                          ?.buildSuggestionTitleWidget(),
                                      subtitle: item.place
                                          ?.buildSuggestionSubtitleWidget(),
                                    );
                            },
                            separatorBuilder: (context, index) => Divider(),
                            itemCount:
                                state.destinationSuggestions?.data?.length ?? 0,
                          );
                        }
                        return SizedBox();
                      },
                    );
                  } else {
                    return DefaultTabController(
                      length: TruckNavigationStaticDetails.locationOpt.length,
                      child: Column(
                        children: [
                          CustomTabBarWidget(
                            options: TruckNavigationStaticDetails.locationOpt,
                          ),
                          15.h,
                          SizedBox(
                            height: context.screenHeight * 0.5,
                            child: TabBarView(
                              children: [
                                showRecentSearches(
                                  context,
                                  onSelect: (searchHistory) {
                                    destinationController.text =
                                        searchHistory.title;

                                    context
                                        .read<TruckNavigationCubit>()
                                        .selectRecentAsDestination(
                                          searchHistory,
                                        );

                                    if (onContinue != null) {
                                      onContinue(destinationController.text);
                                    }
                                    Navigator.pop(context);
                                    context
                                        .read<TruckNavigationCubit>()
                                        .calculateRoute();
                                  },
                                ),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) =>
                                      PlaceDisplayWidget(
                                        place: TruckNavigationStaticDetails
                                            .placess[index],
                                        isSaved: true,
                                      ),
                                  itemCount: TruckNavigationStaticDetails
                                      .placess
                                      .length,
                                ),

                                ListView.builder(
                                  shrinkWrap: true,
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
                    );
                  }
                },
              ),
              20.h,
            ],
          ),
        ),
      ),
    );
  }

  static void editLocationSheet(
    BuildContext context, {
    Function(dynamic place)? onContinue,
  }) {
    final TextEditingController locationController = TextEditingController();

    final FocusNode locationFocusNode = FocusNode();
    ValueNotifier showRecentTab = ValueNotifier(true);

    // Auto-focus on destination field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      locationFocusNode.requestFocus();
    });

    locationController.addListener(() {
      if (locationController.text.isNotEmpty && showRecentTab.value) {
        showRecentTab.value = false;
      } else if (locationController.text.isEmpty && !showRecentTab.value) {
        showRecentTab.value = true;
      }
      Future.delayed(Duration(milliseconds: 400), () {
        if (context.mounted) {
          context.read<TruckNavigationCubit>().searchPlaces(
            locationController.text,
          );
        }
      });
    });

    bool isLoading = false;

    Helpers.openBottomSheet(
      context: context,
      child: SizedBox(
        height: context.screenHeight * 0.9,

        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.horizontalPadding),
          child: Column(
            children: [
              CustomTextfieldWidget(
                focusNode: locationFocusNode,
                onTapOutside: (_) => locationFocusNode.unfocus(),
                prefixIcon: SvgPicture.asset(AppIcons.searchIcon),
                hintText: "Enter location",
                controller: locationController,
                suffixIcon: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(Icons.close, color: Colors.black),
                ),
              ),
              20.h,
              GestureDetector(
                onTap: () => context.pushPage(
                  PickLocationFromMap(
                    onPlacePicked: (picked) {
                      if (onContinue != null) {
                        onContinue(picked);

                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColorTheme().whiteShade,
                      child: Image.asset(
                        AppImages.blackPointPin,
                        width: 20,
                        height: 20,
                      ),
                    ),
                    12.w,
                    Text(
                      'Choose on map',
                      style: AppTextTheme().bodyText.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              20.h,
              ValueListenableBuilder(
                valueListenable: showRecentTab,
                builder: (_, val, c) {
                  if (!val) {
                    return BlocBuilder<
                      TruckNavigationCubit,
                      TruckNavigationState
                    >(
                      buildWhen: (p, c) =>
                          p.destinationSuggestions != c.destinationSuggestions,
                      builder: (context, state) {
                        if (locationController.text.isNotEmpty &&
                            (state.destinationSuggestions?.data ?? [])
                                .isNotEmpty) {
                          return ListView.separated(
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              final Suggestion? item =
                                  state.destinationSuggestions?.data?[index];
                              return item == null
                                  ? SizedBox()
                                  : ListTile(
                                      onTap: () {
                                        locationController.text = item.title;
                                        if (locationController
                                            .text
                                            .isNotEmpty) {
                                          if (onContinue != null) {
                                            onContinue(item.place);
                                          }

                                          Navigator.pop(context);
                                        }
                                      },
                                      contentPadding: EdgeInsets.zero,
                                      leading: Column(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Color(0xffF4F6F8),
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
                                                  color:
                                                      AppColorTheme().secondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                      title: item.place
                                          ?.buildSuggestionTitleWidget(),
                                      subtitle: item.place
                                          ?.buildSuggestionSubtitleWidget(),
                                    );
                            },
                            separatorBuilder: (context, index) => Divider(),
                            itemCount:
                                state.destinationSuggestions?.data?.length ?? 0,
                          );
                        }
                        return SizedBox();
                      },
                    );
                  } else {
                    return DefaultTabController(
                      length: TruckNavigationStaticDetails.locationOpt.length,
                      child: Column(
                        children: [
                          CustomTabBarWidget(
                            options: TruckNavigationStaticDetails.locationOpt,
                          ),
                          15.h,
                          SizedBox(
                            height: context.screenHeight * 0.5,
                            child: TabBarView(
                              children: [
                                showRecentSearches(
                                  context,
                                  onSelect: (item) {
                                    locationController.text = item.title;
                                    // context
                                    //     .read<TruckNavigationCubit>()
                                    //     .selectRecentAsDestination(item);
                                    if (locationController.text.isNotEmpty) {
                                      if (onContinue != null) {
                                        onContinue(item);
                                      }
                                      // context
                                      //     .read<TruckNavigationCubit>()
                                      //     .calculateRoute();

                                      Navigator.pop(context);
                                    }
                                  },
                                ),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) =>
                                      PlaceDisplayWidget(
                                        place: TruckNavigationStaticDetails
                                            .placess[index],
                                        isSaved: true,
                                      ),
                                  itemCount: TruckNavigationStaticDetails
                                      .placess
                                      .length,
                                ),

                                ListView.builder(
                                  shrinkWrap: true,
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
                    );
                  }
                },
              ),
              20.h,
            ],
          ),
        ),
      ),
    );
  }

  static Widget showRecentSearches(
    BuildContext context, {
    Function(RecentSearchModel searchHistory)? onSelect,
  }) {
    return BlocBuilder<RecentSearchCubit, RecentSearchState>(
      builder: (context, state) {
        if (state.isLoading) return Center(child: CircularProgressIndicator());

        if (state.searches.isEmpty) {
          return Center(child: Text("No recent searches"));
        }

        return ListView.builder(
          itemCount: state.searches.length,
          itemBuilder: (context, index) {
            final item = state.searches[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () {
                if (onSelect != null) onSelect(item);
              },
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: Color(0xffF4F6F8),
                child: SvgPicture.asset(AppIcons.frameIcon),
              ),
              title: item.buildSuggestionTitleWidget(),
              subtitle: item.buildSuggestionSubtitleWidget(),
            );
          },
        );
      },
    );
  }
}
