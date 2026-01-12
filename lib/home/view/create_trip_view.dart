import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ommo/custom_widget/custom_widget.dart';
import 'package:ommo/home/view/home_mobile_view.dart';
import 'package:ommo/home/view/home_utils.dart';
import 'package:ommo/home/view/truck_navigation/truck_navigation_static_details.dart';
import 'package:ommo/logic/cubit/create_trip/create_trip_cubit.dart';
import 'package:ommo/logic/cubit/create_trip/create_trip_state.dart';
import 'package:ommo/logic/cubit/truck_navigation/truck_navigation_cubit.dart';
import 'package:ommo/logic/cubit/truck_navigation/truck_navigation_state.dart';
import 'package:ommo/services/hive/recent_search/cubit/recent_search_cubit.dart';
import 'package:ommo/utils/constants/constants.dart';
import 'package:ommo/utils/extension/place_extension.dart';
import 'package:ommo/utils/extension/recent_search_model_extension.dart';
import 'package:ommo/utils/generics/generics.dart';
import 'package:ommo/utils/theme/theme.dart';

class CreateTripView extends StatefulWidget {
  const CreateTripView({super.key});

  @override
  State<CreateTripView> createState() => _CreateTripViewState();
}

class _CreateTripViewState extends State<CreateTripView> {
  late final TextEditingController startController;
  late final TextEditingController destinationController;
  late final FocusNode startFocus;
  late final FocusNode destinationFocus;
  late CreateTripCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = CreateTripCubit(context.read<RecentSearchCubit>());

    startController = TextEditingController(text: "Your Location");
    destinationController = TextEditingController();
    startFocus = FocusNode();
    destinationFocus = FocusNode();

    // Focus listeners
    startFocus.addListener(() {
      if (startFocus.hasFocus && _cubit.state.isMyLocationSelected) {
        startController.clear();
      }
      if (!startFocus.hasFocus && _cubit.state.isMyLocationSelected) {
        startController.text = 'Your Location';
      }

      _cubit.onStartFocusChanged(startFocus.hasFocus, startController.text);
    });
    destinationFocus.addListener(() {
      _cubit.onDestinationFocusChanged(
        destinationFocus.hasFocus,
        destinationController.text,
      );
    });

    // Text field listeners
    startController.addListener(() {
      _cubit.onStartChanged(startController.text);
    });
    destinationController.addListener(() {
      _cubit.onDestinationChanged(destinationController.text);
    });

    // Set initial start point
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cubit.setInitialStartPoint();
    });
  }

  @override
  void dispose() {
    startController.dispose();
    destinationController.dispose();
    startFocus.dispose();
    destinationFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _cubit,
      child: BlocListener<TruckNavigationCubit, TruckNavigationState>(
        listener: (context, state) {
          if (state.currentRoute != null && state.hasDirection) {
            Navigator.maybePop(context);
          }
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.horizontalPadding),
          child: Column(
            children: [
              buildHeader(context),
              SizedBox(height: 20),
              VerticalStepWithTextField(
                textControllers: [startController, destinationController],
                focusNode: [startFocus, destinationFocus],
                removeFieldTap: () {},
                readOnly: [false, false],
                autoFocusIndex: 1,
              ),
              SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(child: buildContent(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSuggestions(BuildContext context) {
    return BlocBuilder<CreateTripCubit, CreateTripState>(
      buildWhen: (previous, current) =>
          previous.destinationSuggestions != current.destinationSuggestions ||
          previous.startSuggestions != current.startSuggestions ||
          previous.hasStartFocus != current.hasStartFocus,
      builder: (context, state) {
        final suggestions = state.hasStartFocus
            ? state.startSuggestions
            : state.destinationSuggestions;

        if (suggestions.isEmpty) return const SizedBox();

        return ListView.separated(
          shrinkWrap: true,
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final item = suggestions[index];
            if (item.place == null) return const SizedBox();

            return ListTile(
              onTap: () {
                context.read<CreateTripCubit>().selectSuggestion(item.place!);
                if (state.hasStartFocus) {
                  if ((item.place?.formattedTitle ?? '').isNotEmpty) {
                    startController.text = item.place?.formattedTitle ?? '';

                    destinationFocus.requestFocus();
                  }
                } else {
                  if ((item.place?.formattedTitle ?? '').isNotEmpty) {
                    destinationController.text =
                        item.place?.formattedTitle ?? '';
                    destinationFocus.unfocus();
                  }
                }
              },
              contentPadding: EdgeInsets.zero,
              leading: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xffF4F6F8),
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
                    style: AppTextTheme().lightText.copyWith(
                      fontSize: 12,
                      color: AppColorTheme().secondary,
                    ),
                  ),
                ],
              ),
              title: item.place?.buildSuggestionTitleWidget(),
              subtitle: item.place?.buildSuggestionSubtitleWidget(),
            );
          },
          separatorBuilder: (_, __) => const Divider(),
        );
      },
    );
  }

  Widget buildContent(BuildContext context) {
    return BlocBuilder<CreateTripCubit, CreateTripState>(
      buildWhen: (p, c) =>
          p.showYourLocationTab != c.showYourLocationTab ||
          p.showRecentTab != c.showRecentTab,
      builder: (context, state) {
        final cubit = context.read<CreateTripCubit>();

        return Column(
          children: [
            if (state.showYourLocationTab) ...[
              InkWell(
                onTap: () {
                  startController.text = "Your Location";
                  cubit.selectCurrentAsStartingPlace();
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColorTheme().primary.withValues(
                        alpha: 0.2,
                      ),
                      child: SvgPicture.asset(AppIcons.navigationIconGreen),
                    ),
                    12.w,
                    Text(
                      'Your location',
                      style: AppTextTheme().bodyText.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              20.h,
            ],
            !state.showRecentTab
                ? buildSuggestions(context)
                : buildTabBars(context),
            20.h,
          ],
        );
      },
    );
  }

  Widget buildTabBars(BuildContext context) {
    return DefaultTabController(
      length: TruckNavigationStaticDetails.locationOpt.length,
      child: Column(
        children: [
          CustomTabBarWidget(options: TruckNavigationStaticDetails.locationOpt),
          15.h,
          SizedBox(
            height: context.screenHeight * 0.5,
            child: TabBarView(
              children: [
                BlocBuilder<CreateTripCubit, CreateTripState>(
                  buildWhen: (p, c) => p.hasStartFocus != c.hasStartFocus,
                  builder: (context, state) {
                    return HomeUtils.showRecentSearches(
                      context,
                      onSelect: (searchHistory) {
                        if (state.hasStartFocus) {
                          if (searchHistory.formattedTitle.isNotEmpty) {
                            startController.text = searchHistory.formattedTitle;
                            destinationFocus.requestFocus();
                          }
                        } else {
                          if (searchHistory.formattedTitle.isNotEmpty) {
                            destinationController.text =
                                searchHistory.formattedTitle;
                            destinationFocus.unfocus();
                          }
                        }
                        context
                            .read<CreateTripCubit>()
                            .selectRecentAsLocationPoint(searchHistory);
                      },
                    );
                  },
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: TruckNavigationStaticDetails.placess.length,
                  itemBuilder: (context, index) => PlaceDisplayWidget(
                    place: TruckNavigationStaticDetails.placess[index],
                    isSaved: true,
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: TruckNavigationStaticDetails.terminals.length,
                  itemBuilder: (context, index) => PlaceDisplayWidget(
                    place: TruckNavigationStaticDetails.terminals[index],
                    isSaved: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHeader(BuildContext context) {
    return Row(
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
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.black),
        ),
      ],
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:here_sdk/search.dart';
// import 'package:ommo/custom_widget/custom_widget.dart';
// import 'package:ommo/home/view/home_mobile_view.dart';
// import 'package:ommo/home/view/home_utils.dart';
// import 'package:ommo/home/view/truck_navigation/truck_navigation_static_details.dart';
// import 'package:ommo/logic/cubit/truck_navigation/truck_navigation_cubit.dart';
// import 'package:ommo/logic/cubit/truck_navigation/truck_navigation_state.dart';
// import 'package:ommo/services/hive/recent_search/cubit/recent_search_cubit.dart';
// import 'package:ommo/utils/constants/constants.dart';
// import 'package:ommo/utils/extension/place_extension.dart';
// import 'package:ommo/utils/generics/generics.dart';
// import 'package:ommo/utils/snacks/snackbar_utils.dart';
// import 'package:ommo/utils/theme/theme.dart';

// class CreateTripView extends StatefulWidget {
//   const CreateTripView({super.key});

//   @override
//   State<CreateTripView> createState() => _CreateTripViewState();
// }

// class _CreateTripViewState extends State<CreateTripView> {
//   final TextEditingController startController = TextEditingController(
//     text: "Your Location",
//   );
//   final TextEditingController destinationController = TextEditingController();
//   final FocusNode startFocus = FocusNode();
//   final FocusNode destinationFocusNode = FocusNode();
//   ValueNotifier showRecentTab = ValueNotifier(true);
//   ValueNotifier showYourLocationTab = ValueNotifier(true);
//   bool isLoading = false;
//   LocationPoint? startPoint;
//   LocationPoint? currentStartPoint;
//   LocationPoint? destinationPoint;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       startPoint = LocationPoint(
//         place: context.read<TruckNavigationCubit>().state.currentPlace?.data,
//         pointType: LocationPointType.starting,
//       );
//       destinationFocusNode.requestFocus();
//     });

//     startFocus.addListener(() {
//       if (startFocus.hasFocus && startController.text != "Your Location") {
//         showYourLocationTab.value = true;
//       } else {
//         showYourLocationTab.value = false;
//       }
//       context.read<TruckNavigationCubit>().searchPlaces(
//         startController.text == 'Your Location' ? '' : startController.text,
//       );
//     });

//     destinationFocusNode.addListener(() {
//       context.read<TruckNavigationCubit>().searchPlaces(
//         destinationController.text,
//       );
//     });

//     startController.addListener(() {
//       if (startController.text.isNotEmpty && showRecentTab.value) {
//         showRecentTab.value = false;
//       } else if (startController.text.isEmpty && !showRecentTab.value) {
//         showRecentTab.value = true;
//       }
//       if (startFocus.hasFocus && startController.text != "Your Location") {
//         showYourLocationTab.value = true;
//       } else {
//         showYourLocationTab.value = false;
//       }
//       Future.delayed(Duration(milliseconds: 400), () {
//         if (context.mounted) {
//           context.read<TruckNavigationCubit>().searchPlaces(
//             startController.text == 'Your Location' ? '' : startController.text,
//           );
//         }
//       });
//     });

//     destinationController.addListener(() {
//       if (destinationController.text.isNotEmpty && showRecentTab.value) {
//         showRecentTab.value = false;
//       } else if (destinationController.text.isEmpty && !showRecentTab.value) {
//         showRecentTab.value = true;
//       }
//       if (startFocus.hasFocus && startController.text != "Your Location") {
//         showYourLocationTab.value = true;
//       } else {
//         showYourLocationTab.value = false;
//       }
//       Future.delayed(Duration(milliseconds: 400), () {
//         if (context.mounted) {
//           context.read<TruckNavigationCubit>().searchPlaces(
//             destinationController.text,
//           );
//         }
//       });
//     });
//   }

//   selectSuggestion(BuildContext context, Place _place) {
//     if (isLoading) return;
//     context.read<RecentSearchCubit>().addSearchFromPlace(_place);
//     if (startFocus.hasFocus) selectStartingPlace(context, _place);
//     if (destinationFocusNode.hasFocus) selectDestinationPlace(context, _place);
//   }

//   selectStartingPlace(BuildContext context, dynamic _place) {
//     currentStartPoint = startPoint;
//     startPoint = LocationPoint(
//       place: _place,
//       pointType: LocationPointType.starting,
//     );
//     startController.text = _place.formattedTitle;
//     showYourLocationTab.value = true;
//     checkIfBothEntered(context);
//   }

//   selectCurrentAsStartingPlace(BuildContext context) {
//     startController.text = "Your Location";
//     startPoint = currentStartPoint;
//     showYourLocationTab.value = false;
//     checkIfBothEntered(context);
//   }

//   selectDestinationPlace(BuildContext context, dynamic _place) {
//     destinationPoint = _place;
//     destinationController.text = _place.formattedTitle;
//     checkIfBothEntered(context);
//   }

//   checkIfBothEntered(BuildContext context) {
//     if (isLoading) return;
//     if (startPoint == null) {
//       SnackbarUtils.showWarningSnackBar(
//         context,
//         "Please select start location",
//       );
//       return;
//     }
//     if (destinationPoint == null) {
//       SnackbarUtils.showWarningSnackBar(
//         context,
//         "Please select start location",
//       );
//       return;
//     }
//     context.read<TruckNavigationCubit>().createTrip([
//       startPoint!,
//       destinationPoint!,
//     ]);
//     context.read<TruckNavigationCubit>().calculateRoute();
//     isLoading = true;
//   }

//   @override
//   void dispose() {
//     startFocus.dispose();
//     destinationFocusNode.dispose();
//     startController.dispose();
//     destinationController.dispose();

//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: AppTheme.horizontalPadding),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 "Create a trip",
//                 style: AppTextTheme().subHeadingText.copyWith(
//                   fontWeight: AppFontWeight.semiBold,
//                   fontSize: 20,
//                 ),
//               ),
//               IconButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 icon: Icon(Icons.close, color: Colors.black),
//               ),
//             ],
//           ),
//           20.h,
//           VerticalStepWithTextField(
//             textControllers: [startController, destinationController],
//             focusNode: [startFocus, destinationFocusNode],
//             removeFieldTap: () {},
//             readOnly: [false, false],
//           ),
//           20.h,

//           ValueListenableBuilder(
//             valueListenable: showYourLocationTab,
//             builder: (cnt, val, c) {
//               return Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: val
//                     ? [
//                         GestureDetector(
//                           onTap: () => selectCurrentAsStartingPlace(context),
//                           child: Row(
//                             children: [
//                               CircleAvatar(
//                                 radius: 20,
//                                 backgroundColor: AppColorTheme().primary
//                                     .withValues(alpha: 0.2),
//                                 child: SvgPicture.asset(
//                                   AppIcons.navigationIconGreen,
//                                 ),
//                               ),
//                               12.w,
//                               Text(
//                                 'Your location',
//                                 style: AppTextTheme().bodyText.copyWith(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         20.h,
//                       ]
//                     : [],
//               );
//             },
//           ),
//           ValueListenableBuilder(
//             valueListenable: showRecentTab,
//             builder: (_, val, c) {
//               if (!val) {
//                 return BlocConsumer<TruckNavigationCubit, TruckNavigationState>(
//                   listener: (context, state) {
//                     if (state.currentRoute != null && state.hasDirection) {
//                       isLoading = true;
//                       Navigator.pop(context);
//                     }
//                   },
//                   listenWhen: (previous, current) =>
//                       previous.currentRoute != current.currentRoute,

//                   buildWhen: (p, c) =>
//                       p.destinationSuggestions != c.destinationSuggestions,
//                   builder: (context, state) {
//                     if ((destinationController.text.isNotEmpty ||
//                             startController.text.isNotEmpty) &&
//                         (state.destinationSuggestions?.data ?? []).isNotEmpty) {
//                       return ListView.separated(
//                         shrinkWrap: true,
//                         itemBuilder: (context, index) {
//                           final Suggestion? item =
//                               state.destinationSuggestions?.data?[index];
//                           return item == null
//                               ? SizedBox()
//                               : ListTile(
//                                   onTap: () {
//                                     selectSuggestion(context, item.place!);
//                                   },
//                                   contentPadding: EdgeInsets.zero,
//                                   leading: Column(
//                                     children: [
//                                       CircleAvatar(
//                                         backgroundColor: Color(0xffF4F6F8),
//                                         radius: 16,
//                                         child: Image.asset(
//                                           AppImages.suggestionPin,
//                                           height: 20,
//                                           width: 20,
//                                         ),
//                                       ),
//                                       Text(
//                                         item.place?.distanceInMiles ?? '',
//                                         maxLines: 2,
//                                         style: AppTextTheme().lightText
//                                             .copyWith(
//                                               fontSize: 12,
//                                               color: AppColorTheme().secondary,
//                                             ),
//                                       ),
//                                     ],
//                                   ),
//                                   title: item.place
//                                       ?.buildSuggestionTitleWidget(),
//                                   subtitle: item.place
//                                       ?.buildSuggestionSubtitleWidget(),
//                                 );
//                         },
//                         separatorBuilder: (context, index) => Divider(),
//                         itemCount:
//                             state.destinationSuggestions?.data?.length ?? 0,
//                       );
//                     }
//                     return SizedBox();
//                   },
//                 );
//               } else {
//                 return DefaultTabController(
//                   length: TruckNavigationStaticDetails.locationOpt.length,
//                   child: Column(
//                     children: [
//                       CustomTabBarWidget(
//                         options: TruckNavigationStaticDetails.locationOpt,
//                       ),
//                       15.h,
//                       SizedBox(
//                         height: context.screenHeight * 0.5,
//                         child: TabBarView(
//                           children: [
//                             HomeUtils.showRecentSearches(
//                               context,
//                               onSelect: (searchHistory) {
//                                 destinationController.text =
//                                     searchHistory.title;

//                                 context
//                                     .read<TruckNavigationCubit>()
//                                     .selectRecentAsDestination(searchHistory);

//                                 // if (onContinue != null) {
//                                 //   onContinue(destinationController.text);
//                                 // }
//                                 Navigator.pop(context);
//                                 context
//                                     .read<TruckNavigationCubit>()
//                                     .calculateRoute();
//                               },
//                             ),
//                             ListView.builder(
//                               shrinkWrap: true,
//                               physics: NeverScrollableScrollPhysics(),
//                               itemBuilder: (context, index) =>
//                                   PlaceDisplayWidget(
//                                     place: TruckNavigationStaticDetails
//                                         .placess[index],
//                                     isSaved: true,
//                                   ),
//                               itemCount:
//                                   TruckNavigationStaticDetails.placess.length,
//                             ),

//                             ListView.builder(
//                               shrinkWrap: true,
//                               physics: NeverScrollableScrollPhysics(),
//                               itemBuilder: (context, index) =>
//                                   PlaceDisplayWidget(
//                                     place: TruckNavigationStaticDetails
//                                         .terminals[index],
//                                     isSaved: true,
//                                   ),
//                               itemCount:
//                                   TruckNavigationStaticDetails.terminals.length,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               }
//             },
//           ),
//           20.h,
//         ],
//       ),
//     );
//   }
// }
