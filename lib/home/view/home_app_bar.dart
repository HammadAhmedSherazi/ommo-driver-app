import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ommo/home/view/truck_specification/truck_specification_utils.dart';
import 'package:ommo/utils/constants/constants.dart';
import 'package:ommo/utils/utils.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.screenHeight * 0.080,
      width: context.screenWidth * 0.95,
      decoration: BoxDecoration(
        color: AppColorTheme().white,

        border: Border.all(width: 1, color: Color(0xffEBEEF2)),
        borderRadius: BorderRadius.circular(100),
      ),
      padding: EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Column(
              children: [
                SvgPicture.asset(AppIcons.weatherIcon, width: 32, height: 32),
                Text(
                  '24 °C',
                  style: AppTextTheme().bodyText.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Image.asset(AppIcons.logo, width: 126, height: 22),
          InkWell(
            onTap: () =>
                TruckSpecificationUtils.openSettingBottomSheet(context),
            child: Container(
              height: 44,
              width: 44,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Color(0xFFEBEEF2),
                  width: 1,
                ), // rgba(235, 238, 242, 1)
                borderRadius: BorderRadius.circular(100), // Optional
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
          ),
        ],
      ),
    );
  }
}
