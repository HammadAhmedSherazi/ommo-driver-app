import 'package:flutter_bloc/flutter_bloc.dart';

enum TruckingState { initial, destinationConfirmed, navigating }

class TruckingStateCubit extends Cubit<TruckingState> {
  TruckingStateCubit(super.initialState);

  void destinationConfirmed() {
    emit(TruckingState.destinationConfirmed);
  }

  void setToInitial() {
    emit(TruckingState.initial);
  }

  void navigationStarted() {
    emit(TruckingState.destinationConfirmed);
  }
}
