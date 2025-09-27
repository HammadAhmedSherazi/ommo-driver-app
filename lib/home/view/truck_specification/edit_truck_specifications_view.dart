import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ommo/app/views/app_view.dart';
import 'package:ommo/custom_widget/custom_widget.dart';
import 'package:ommo/home/view/home_mobile_view.dart';
import 'package:ommo/logic/cubit/truck_specifications/truck_specification_cubit.dart';
import 'package:ommo/logic/cubit/truck_specifications/truck_specifications_state.dart';
import 'package:ommo/utils/helpers/validation.dart';
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

  late ValueNotifier<String?> axleCount;

  @override
  void initState() {
    super.initState();
    context.read<TruckSpecificationsCubit>().initEditState();
    final initialState = context.read<TruckSpecificationsCubit>().initialState;

    lengthFeetController = TextEditingController(
      text: initialState['lengthInFeet'] ?? '',
    );
    lengthInchController = TextEditingController(
      text: initialState['lengthInInches'] ?? '',
    );

    heightFeetController = TextEditingController(
      text: initialState['heightInFeet'] ?? '',
    );
    heightInchController = TextEditingController(
      text: initialState['heightInInches'] ?? '',
    );

    widthFeetController = TextEditingController(
      text: initialState['widthInFeet'] ?? '',
    );
    widthInchController = TextEditingController(
      text: initialState['widthInInches'] ?? '',
    );

    weightController = TextEditingController(
      text: initialState['weightInLbs'] ?? '',
    );

    weightPerAxleController = TextEditingController(
      text: initialState['weightPerAxleInLbs'] ?? '',
    );

    axleCount = ValueNotifier(initialState['axleCount']);
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
    navigatorKey.currentContext
        ?.read<TruckSpecificationsCubit>()
        .clearEditState();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final truckSpecsCubit = context.read<TruckSpecificationsCubit>();
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
                        truckSpecsCubit.editTruckSpecs();
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
                        controller: lengthFeetController,
                        validator: Validation.validateFeet,
                        onChanged: (newLength) => truckSpecsCubit.setEditState(
                          'lengthInFeet',
                          newLength,
                        ),
                      ),
                    ),
                    Expanded(
                      child: CustomTextfieldWidget(
                        hintText: "0''",
                        keyboardType: TextInputType.number,
                        controller: lengthInchController,

                        validator: Validation.validateInches,
                        onChanged: (newLength) => truckSpecsCubit.setEditState(
                          'lengthInInches',
                          newLength,
                        ),
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

                        controller: heightFeetController,

                        validator: Validation.validateFeet,
                        onChanged: (newLength) => truckSpecsCubit.setEditState(
                          'heightInFeet',
                          newLength,
                        ),
                      ),
                    ),
                    Expanded(
                      child: CustomTextfieldWidget(
                        hintText: "0''",
                        keyboardType: TextInputType.number,
                        controller: heightInchController,

                        validator: Validation.validateInches,
                        onChanged: (newLength) => truckSpecsCubit.setEditState(
                          'heightInInches',
                          newLength,
                        ),
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
                        controller: widthFeetController,
                        validator: Validation.validateFeet,
                        onChanged: (newLength) => truckSpecsCubit.setEditState(
                          'widthInFeet',
                          newLength,
                        ),
                      ),
                    ),
                    Expanded(
                      child: CustomTextfieldWidget(
                        hintText: "0''",
                        keyboardType: TextInputType.number,
                        controller: widthInchController,

                        validator: Validation.validateInches,
                        onChanged: (newLength) => truckSpecsCubit.setEditState(
                          'widthInInches',
                          newLength,
                        ),
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
                      child: ValueListenableBuilder(
                        valueListenable: axleCount,
                        builder: (_, count, c) {
                          return CustomDropDown<String>(
                            placeholderText: "Select Axle",
                            options: List.generate(
                              5,
                              (index) => CustomDropDownOption(
                                value: '${index + 1}',
                                displayOption: "${index + 1} Axle",
                              ),
                            ),
                            value: count,
                            onChanged: (selected) {
                              axleCount.value = selected;
                              truckSpecsCubit.setEditState(
                                'axleCount',
                                selected,
                              );
                            },
                          );
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
                        hintText: "0",
                        keyboardType: TextInputType.number,
                        controller: weightController,
                        validator: (value) {
                          if ((value ?? '').isEmpty) {
                            return 'Please enter weight';
                          }
                          return null;
                        },
                        onChanged: (newLength) => truckSpecsCubit.setEditState(
                          'weightInLbs',
                          newLength,
                        ),
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
                        "Weight Per Axle",
                        style: AppTextTheme().lightText.copyWith(fontSize: 16),
                      ),
                    ),

                    Expanded(
                      child: CustomTextfieldWidget(
                        hintText: "0",
                        keyboardType: TextInputType.number,
                        controller: weightPerAxleController,
                        validator: (value) {
                          if ((value ?? '').isEmpty) {
                            return 'Please enter weight';
                          }
                          return null;
                        },
                        onChanged: (newLength) => truckSpecsCubit.setEditState(
                          'weightPerAxleInLbs',
                          newLength,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(AppTheme.horizontalPadding),
            child:
                BlocBuilder<TruckSpecificationsCubit, TruckSpecificationState>(
                  builder: (context, state) => CustomButtonWidget(
                    title: "Save",
                    enabled: state.hasChanges,
                    onPressed: () {
                      truckSpecsCubit.editTruckSpecs();
                      context.popPage();
                    },
                  ),
                ),
          ),
          30.h,
        ],
      ),
    );
  }
}
