import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ommo/custom_widget/custom_widget.dart';
import 'package:ommo/home/view/home_utils.dart';
import 'package:ommo/logic/cubit/truck_navigation/truck_navigation_cubit.dart';
import 'package:ommo/logic/cubit/truck_navigation/truck_navigation_state.dart';
import 'package:ommo/models/location_point_model.dart';
import 'package:ommo/utils/utils.dart';

class TripDestinationWidget extends StatefulWidget {
  const TripDestinationWidget({super.key});

  @override
  State<TripDestinationWidget> createState() => _TripDestinationWidgetState();
}

class _TripDestinationWidgetState extends State<TripDestinationWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TruckNavigationCubit, TruckNavigationState>(
      buildWhen: (previous, current) =>
          previous.locationPoints != current.locationPoints,
      builder: (context, state) {
        final points = state.locationPoints ?? [];
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                /// Left side (steps)
                Column(
                  children: List.generate(points.length, (index) {
                    final isFirst = index == 0;
                    final isLast = index == points.length - 1;

                    return Column(
                      children: [
                        // Top icon
                        // if (isFirst) 20.h,
                        if (isFirst)
                          Container(
                            height: 18,
                            width: 18,
                            padding: EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: AppColorTheme().primary,
                              shape: BoxShape.circle,
                              border: Border.all(width: 1, color: Colors.white),
                              boxShadow: [
                                BoxShadow(
                                  offset: Offset(0, 3.2),
                                  blurRadius: 6.4,
                                  spreadRadius: 0,
                                  color: Color(0x7A000000),
                                ),
                                BoxShadow(
                                  offset: Offset(0, 0),
                                  blurRadius: 0,
                                  spreadRadius: 2.4,
                                  color: Color(0xffFFFFFF),
                                ),
                              ],
                            ),
                          )
                        else if (isLast)
                          Container(
                            height: 18,
                            width: 18,
                            padding: EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Color(0xffFF4F5B),
                              shape: BoxShape.circle,
                              border: Border.all(width: 1, color: Colors.white),
                              boxShadow: [
                                BoxShadow(
                                  offset: Offset(0, 3.2),
                                  blurRadius: 6.4,
                                  spreadRadius: 0,
                                  color: Color(0x7A000000),
                                ),
                                BoxShadow(
                                  offset: Offset(0, 0),
                                  blurRadius: 0,
                                  spreadRadius: 2.4,
                                  color: Color(0xffFFFFFF),
                                ),
                              ],
                            ),
                            child: Image.asset(AppImages.destinationPointPin),
                          )
                        else
                          Image.asset(
                            AppImages.stopPointIcon,
                            height: 20,
                            width: 20,
                          ),

                        // Draw dotted line only between items
                        // if (!isLast)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 5.6),
                          child: SizedBox(
                            height: 16, // match with textfield height + spacing
                            child: CustomPaint(painter: DottedLinePainter()),
                          ),
                        ),
                      ],
                    );
                  }),
                ),

                /// Right side (textfields)
                Expanded(
                  child: ReorderableListView.builder(
                    itemCount: points.length,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    cacheExtent: 45,
                    itemExtent: 45,
                    clipBehavior: Clip.none,
                    buildDefaultDragHandles: false,
                    itemBuilder: (_, i) {
                      final isFirst = i == 0;
                      final isLast = i == points.length - 1;

                      return Container(
                        key: ValueKey(points[i].title),
                        margin: EdgeInsets.only(bottom: 25),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            5.w,
                            Expanded(
                              child: GestureDetector(
                                onTap: () => HomeUtils.editLocationSheet(
                                  context,
                                  onContinue: (updatedPlace) {
                                    context
                                        .read<TruckNavigationCubit>()
                                        .editStop(i, updatedPlace);
                                  },
                                ),
                                onLongPress: () {
                                  // if (isFirst || isLast || points.length <= 2)
                                  if (points.length <= 2) return;
                                  showDeleteDialog(
                                    context,
                                    isFirst: isFirst,
                                    isLast: isLast,
                                    item: points[i],
                                    index: i,
                                    onDelete: () => context
                                        .read<TruckNavigationCubit>()
                                        .deleteStop(i),
                                  );
                                },
                                child: Text(
                                  points[i].title ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: AppTextTheme().bodyText.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                            5.w,
                            ReorderableDragStartListener(
                              index: i,
                              child: Image.asset(
                                AppImages.pointDragIcon,
                                height: 20,
                                width: 20,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    onReorder: (oldIndex, newIndex) {
                      context
                          .read<TruckNavigationCubit>()
                          .changeLocationPointOrder(oldIndex, newIndex);
                    },
                  ),
                ),
              ],
            ),

            InkWell(
              onTap: () => HomeUtils.editLocationSheet(
                context,
                onContinue: (place) {
                  context.read<TruckNavigationCubit>().addStop(place);
                },
              ),
              child: Row(
                children: [
                  Image.asset(AppImages.addCircle, height: 20, width: 20),
                  12.w,
                  Text(
                    "Add a stop",
                    style: AppTextTheme().bodyText.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColorTheme().primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  showDeleteDialog(
    BuildContext context, {
    required bool isFirst,
    required bool isLast,
    required LocationPoint item,
    required int index,
    VoidCallback? onDelete,
  }) {
    return showDialog(
      context: context,
      fullscreenDialog: true,

      barrierColor: Colors.transparent,
      builder: (context) => Material(
        color: Colors.transparent,

        child: GestureDetector(
          onTap: () => context.popPage(),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 50),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black54, Colors.black87],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 40,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (isFirst)
                      Container(
                        height: 18,
                        width: 18,
                        padding: EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColorTheme().primary,
                          shape: BoxShape.circle,
                          border: Border.all(width: 1, color: Colors.white),
                          boxShadow: [
                            BoxShadow(
                              offset: Offset(0, 3.2),
                              blurRadius: 6.4,
                              spreadRadius: 0,
                              color: Color(0x7A000000),
                            ),
                            BoxShadow(
                              offset: Offset(0, 0),
                              blurRadius: 0,
                              spreadRadius: 2.4,
                              color: Color(0xffFFFFFF),
                            ),
                          ],
                        ),
                      )
                    else if (isLast)
                      Container(
                        height: 18,
                        width: 18,
                        padding: EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Color(0xffFF4F5B),
                          shape: BoxShape.circle,
                          border: Border.all(width: 1, color: Colors.white),
                          boxShadow: [
                            BoxShadow(
                              offset: Offset(0, 3.2),
                              blurRadius: 6.4,
                              spreadRadius: 0,
                              color: Color(0x7A000000),
                            ),
                            BoxShadow(
                              offset: Offset(0, 0),
                              blurRadius: 0,
                              spreadRadius: 2.4,
                              color: Color(0xffFFFFFF),
                            ),
                          ],
                        ),
                        child: Image.asset(AppImages.destinationPointPin),
                      )
                    else
                      Image.asset(
                        AppImages.stopPointIcon,
                        height: 20,
                        width: 20,
                      ),

                    17.w,
                    Expanded(
                      child: Text(
                        item.title ?? '',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: AppTextTheme().bodyText.copyWith(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    5.w,
                    Image.asset(AppImages.pointDragIcon, height: 20, width: 20),
                  ],
                ),

                CustomButtonWidget(
                  title: "Delete",
                  bgColor: AppColorTheme().red2,
                  onPressed: () {
                    if (onDelete != null) onDelete();
                    context.popPage();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
