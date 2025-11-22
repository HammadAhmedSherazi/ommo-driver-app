import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:here_sdk/search.dart';
import 'package:ommo/custom_widget/custom_widget.dart';
import 'package:ommo/home/view/home_mobile_view.dart';
import 'package:ommo/home/view/truck_navigation/truck_navigation_static_details.dart';
import 'package:ommo/logic/cubit/truck_navigation/truck_navigation_cubit.dart';
import 'package:ommo/logic/cubit/truck_navigation/truck_navigation_state.dart';
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

    // Auto-focus on destination field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      destinationFocusNode.requestFocus();
    });
    destinationController.addListener(() {
      Future.delayed(Duration(milliseconds: 400), () {
        if (context.mounted) {
          context.read<TruckNavigationCubit>().searchPlaces(
            destinationController.text,
          );
        }
      });
    });

    ValueNotifier isLoading = ValueNotifier(false);

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
                readOnly: true,
              ),
              20.h,
              BlocConsumer<TruckNavigationCubit, TruckNavigationState>(
                listener: (context, state) {
                  if (state.currentRoute != null && state.hasDirection) {
                    isLoading.value = true;

                    Navigator.pop(context);
                  }
                },
                listenWhen: (previous, current) =>
                    previous.currentRoute != current.currentRoute,

                buildWhen: (p, c) =>
                    p.destinationSuggestions != c.destinationSuggestions,
                builder: (context, state) {
                  if (destinationController.text.isNotEmpty &&
                      (state.destinationSuggestions?.data ?? []).isNotEmpty) {
                    return ListView.separated(
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        final Suggestion? item =
                            state.destinationSuggestions?.data?[index];
                        return item == null
                            ? SizedBox()
                            : ListTile(
                                onTap: () {
                                  if (isLoading.value) return;
                                  destinationController.text = item.title;
                                  context
                                      .read<TruckNavigationCubit>()
                                      .setDestinationCoordinate(item);
                                  if (destinationController.text.isNotEmpty) {
                                    if (onContinue != null) {
                                      onContinue(destinationController.text);
                                    }
                                    isLoading.value = true;
                                    context
                                        .read<TruckNavigationCubit>()
                                        .calculateRoute();
                                  }
                                },
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: AppColorTheme().primary
                                      .withValues(alpha: 0.2),
                                  child: SvgPicture.asset(
                                    AppIcons.navigationIconGreen,
                                  ),
                                ),
                                title: Text(
                                  item.title,
                                  maxLines: 1,
                                  style: AppTextTheme().bodyText.copyWith(
                                    color: Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  item.place?.address.addressText ?? '',
                                  maxLines: 2,
                                  style: AppTextTheme().lightText.copyWith(
                                    color: AppColorTheme().secondary,
                                  ),
                                ),
                              );
                      },
                      separatorBuilder: (context, index) => Divider(),
                      itemCount:
                          state.destinationSuggestions?.data?.length ?? 0,
                    );
                  }
                  return SizedBox();
                },
              ),
              // Spacer(),
              // BlocListener<TruckNavigationCubit, TruckNavigationState>(
              //   listener: (context, state) {
              //     if (state.currentRoute != null && state.hasDirection) {
              //       isLoading.value = true;

              //       Navigator.pop(context);
              //     }
              //   },
              //   listenWhen: (previous, current) =>
              //       previous.currentRoute != current.currentRoute,

              //   child: ValueListenableBuilder(
              //     valueListenable: isLoading,
              //     builder: (context, value, child) => CustomButtonWidget(
              //       title: 'Continue',
              //       isLoad: value,
              //       onPressed: () async {
              //         if (destinationController.text.isNotEmpty) {
              //           if (onContinue != null) {
              //             onContinue(destinationController.text);
              //           }
              //           isLoading.value = true;
              //           context.read<TruckNavigationCubit>().calculateRoute();
              //         }
              //       },
              //       icon: Icon(Icons.arrow_forward, color: Colors.white),
              //     ),
              //   ),
              // ),
              20.h,
            ],
          ),
        ),
      ),
    );
  }
}
