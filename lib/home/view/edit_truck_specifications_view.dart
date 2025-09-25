import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ommo/custom_widget/custom_widget.dart';
import 'package:ommo/home/view/home_mobile_view.dart';
import 'package:ommo/logic/cubit/truck_specifications/truck_specification_cubit.dart';
import 'package:ommo/utils/extension/num_extension.dart';
import 'package:ommo/utils/utils.dart';

class EditTruckSpecificationsView extends StatefulWidget {
  const EditTruckSpecificationsView({super.key});

  @override
  State<EditTruckSpecificationsView> createState() =>
      _EditTruckSpecificationsViewState();
}

class _EditTruckSpecificationsViewState
    extends State<EditTruckSpecificationsView> {
  late TextEditingController lengthFeetController;
  late TextEditingController lengthInchController;

  late TextEditingController heightFeetController;
  late TextEditingController heightInchController;

  late TextEditingController widthFeetController;
  late TextEditingController widthInchController;

  late TextEditingController weightController;
  late TextEditingController weightPerAxleController;

  @override
  void initState() {
    super.initState();

    final state = context.read<TruckSpecificationsCubit>().state;

    final length = state.lengthInCentimeters.cmToFeetInches;
    final height = state.heightInCentimeters.cmToFeetInches;
    final width = state.widthInCentimeters.cmToFeetInches;

    lengthFeetController = TextEditingController(text: "${length['feet']}");
    lengthInchController = TextEditingController(text: "${length['inches']}");

    heightFeetController = TextEditingController(text: "${height['feet']}");
    heightInchController = TextEditingController(text: "${height['inches']}");

    widthFeetController = TextEditingController(text: "${width['feet']}");
    widthInchController = TextEditingController(text: "${width['inches']}");

    weightController = TextEditingController(
      text: state.grossWeightInKilograms.kgToLbsFormattedString,
    );

    weightPerAxleController = TextEditingController(
      text: state.weightPerAxleInKilograms.kgToLbsFormattedString,
    );
  }

  @override
  void dispose() {
    lengthFeetController.dispose();
    lengthInchController.dispose();
    heightFeetController.dispose();
    heightInchController.dispose();
    widthFeetController.dispose();
    widthInchController.dispose();
    weightController.dispose();
    weightPerAxleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.screenHeight * 0.80,

      child: Column(
        children: [
          Expanded(
            child: ListView(
              // physics: NeverScrollableScrollPhysics(),
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
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.black,
                          size: 18,
                        ),
                      ),
                    ),
                    Text(
                      "Truck Dimensions",
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
                Row(
                  spacing: 10,
                  children: [
                    SvgPicture.asset(AppIcons.lengthIcon),
                    SizedBox(
                      width: context.screenWidth * 0.24,
                      child: Text(
                        "Length",
                        style: AppTextTheme().lightText.copyWith(fontSize: 16),
                      ),
                    ),

                    Expanded(
                      child: CustomTextfieldWidget(
                        hintText: "00'",
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    Expanded(
                      child: CustomTextfieldWidget(
                        hintText: "0''",
                        keyboardType: TextInputType.number,
                      ),
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
                      child: Text(
                        "Height",
                        style: AppTextTheme().lightText.copyWith(fontSize: 16),
                      ),
                    ),

                    Expanded(
                      child: CustomTextfieldWidget(
                        hintText: "00'",
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    Expanded(
                      child: CustomTextfieldWidget(
                        hintText: "0''",
                        keyboardType: TextInputType.number,
                      ),
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
                      child: Text(
                        "Width",
                        style: AppTextTheme().lightText.copyWith(fontSize: 16),
                      ),
                    ),

                    Expanded(
                      child: CustomTextfieldWidget(
                        hintText: "00'",
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    Expanded(
                      child: CustomTextfieldWidget(
                        hintText: "0''",
                        keyboardType: TextInputType.number,
                      ),
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
                      child: Text(
                        "Axle Count",
                        style: AppTextTheme().lightText.copyWith(fontSize: 16),
                      ),
                    ),

                    Expanded(
                      child: CustomDropDown<int>(
                        placeholderText: "Select Axle",
                        options: List.generate(
                          5,
                          (index) => CustomDropDownOption(
                            value: index + 1,
                            displayOption: "${index + 1} Axle",
                          ),
                        ),
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
                      child: Text(
                        "Weight",
                        style: AppTextTheme().lightText.copyWith(fontSize: 16),
                      ),
                    ),

                    Expanded(
                      child: CustomTextfieldWidget(
                        hintText: "0''",
                        keyboardType: TextInputType.number,
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
              title: "Save",
              onPressed: () {
                context.popPage();
              },
            ),
          ),
          30.h,
        ],
      ),
    );
  }
}
