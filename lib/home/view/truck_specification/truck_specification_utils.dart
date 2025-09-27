import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ommo/home/view/home_mobile_view.dart';
import 'package:ommo/home/view/truck_specification/edit_truck_specifications_view.dart';
import 'package:ommo/home/view/truck_navigation/truck_navigation_static_details.dart';
import 'package:ommo/logic/cubit/truck_specifications/truck_specification_cubit.dart';
import 'package:ommo/logic/cubit/truck_specifications/truck_specifications_state.dart';
import 'package:ommo/utils/utils.dart';

class TruckSpecificationUtils {
  static _setRestrictionIcon(String key) {
    switch (key) {
      case "highways":
        return AppIcons.roadIcon;
      case "tolls":
        return AppIcons.flyoverIcon;
      case "ferries":
        return AppIcons.directionBoatIcon;
      case "tunnels":
        return AppIcons.subwayIcon;
      case "unpaved_roads":
        return AppIcons.unpavedRoadIcon;
    }
  }

  static _setRestrictiontitle(String key) {
    switch (key) {
      case "highways":
        return "Avoid Highways";
      case "tolls":
        return "Avoid Tolls";
      case "ferries":
        return "Avoid Ferries";
      case "tunnels":
        return "Avoid Tunnels";
      case "unpaved_roads":
        return "Avoid Unpaved Roads";
    }
  }

  static void openSettingBottomSheet(BuildContext context) {
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
            BlocBuilder<TruckSpecificationsCubit, TruckSpecificationState>(
              buildWhen: (p, c) => p.avoidance != c.avoidance,
              builder: (context, state) {
                return Column(
                  children: List.generate(
                    state.avoidance.length,
                    (index) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: SvgPicture.asset(
                        _setRestrictionIcon(
                          state.avoidance.entries.elementAt(index).key,
                        ),
                      ),
                      title: Text(
                        _setRestrictiontitle(
                          state.avoidance.entries.elementAt(index).key,
                        ),
                        style: AppTextTheme().lightText,
                      ),
                      visualDensity: const VisualDensity(vertical: -4.0),
                      trailing: Transform.scale(
                        scale: 0.6,
                        child: Switch.adaptive(
                          value: state.avoidance.entries.elementAt(index).value,
                          onChanged: (v) {
                            context
                                .read<TruckSpecificationsCubit>()
                                .toggleAvoidance(
                                  state.avoidance.entries.elementAt(index).key,
                                );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
