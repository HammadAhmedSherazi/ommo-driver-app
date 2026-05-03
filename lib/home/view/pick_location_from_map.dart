import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/search.dart';
import 'package:ommo/custom_widget/future_data_builder.dart';
import 'package:ommo/logic/cubit/pick_location_cubit.dart/pick_location_cubit.dart';
import 'package:ommo/logic/cubit/pick_location_cubit.dart/pick_location_state.dart';
import 'package:ommo/logic/cubit/truck_navigation/truck_navigation_cubit.dart';
import 'package:ommo/models/models.dart';
import 'package:ommo/utils/extension/place_data_model.dart';
import 'package:ommo/utils/extension/place_extension.dart';
import 'package:ommo/utils/generics/generics.dart';
import 'package:ommo/utils/helpers/helpers.dart';
import 'package:ommo/utils/theme/theme.dart';

class PickLocationFromMap extends StatefulWidget {
  final Function(PlaceDataModel place)? onPlacePicked;
  const PickLocationFromMap({super.key, this.onPlacePicked});

  @override
  State<PickLocationFromMap> createState() => _PickLocationFromMapState();
}

class _PickLocationFromMapState extends State<PickLocationFromMap> {
  late PickLocationCubit _cubit;

  @override
  void initState() {
    _cubit = PickLocationCubit(
      context.read<TruckNavigationCubit>().state.startCoordinates,
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PickLocationCubit>(
      create: (context) => _cubit,
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: 30,
          centerTitle: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                "Select Location",
                style: AppTextTheme().subHeadingText2.copyWith(
                  color: AppColorTheme().black,
                ),
              ),
              Text(
                "Pan and move map under pin",
                style: AppTextTheme().bodyText.copyWith(
                  color: AppColorTheme().grey,
                ),
              ),
            ],
          ),

          actions: [
            BlocBuilder<PickLocationCubit, PickLocationState>(
              builder: (context, state) {
                return IconButton(
                  onPressed: () {
                    Helpers.print(
                      "state.selectedPlace?.data ${state.selectedPlace?.data}",
                    );
                    if (widget.onPlacePicked != null &&
                        state.selectedPlace?.data != null) {
                      widget.onPlacePicked!(state.selectedPlace!.data!);
                    }
                    context.popPage();
                  },
                  icon: Icon(
                    Icons.check,
                    color: AppColorTheme().primary,
                    size: 30,
                  ),
                );
              },
            ),
            10.w,
          ],
        ),

        body: Stack(
          children: [
            // MapView(),
            BlocBuilder<PickLocationCubit, PickLocationState>(
              buildWhen: (p, c) => p.mapController != c.mapController,
              builder: (context, state) {
                return SafeArea(
                  child: HereMap(
                    onMapCreated: context
                        .read<PickLocationCubit>()
                        .onMapCreated,
                  ),
                );
              },
            ),
            // fixed pin in center
            Align(
              alignment: Alignment.center,
              child: Icon(Icons.location_pin, size: 40, color: Colors.red),
            ),
          ],
        ),
        bottomSheet: BlocBuilder<PickLocationCubit, PickLocationState>(
          builder: (context, state) => SizedBox(
            height: 120,
            child: FutureDataBuilder(
              future: state.selectedPlace,
              onSuccess: (data) => data != null
                  ? Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: 30,
                        horizontal: 20,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColorTheme().whiteShade,
                            child: Icon(
                              Icons.directions,
                              color: AppColorTheme().grey,
                              size: 18,
                            ),
                          ),
                          12.w,
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                data.buildSuggestionTitleWidget(),
                                data.buildSuggestionSubtitleWidget(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
