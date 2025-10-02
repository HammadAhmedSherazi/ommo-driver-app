import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ommo/logic/cubit/truck_specifications/truck_specifications_state.dart';
import 'package:ommo/utils/extension/num_extension.dart';

class TruckSpecificationsCubit extends Cubit<TruckSpecificationState> {
  TruckSpecificationsCubit() : super(TruckSpecificationState());

  late Map<String, String> initialState;
  late Map<String, String> editState;

  void setEditState(key, value) {
    if (editState[key] == initialState[key]) {
      editState.remove(key);
    } else {
      editState[key] = value;
    }

    if (editState.isNotEmpty) {
      setHasChanges(true);
    } else {
      setHasChanges(false);
    }
  }

  void initEditState() {
    editState = {};

    initialState = {
      'lengthInFeet':
          "${state.lengthInCentimeters.cmToFeetInches['feet'] ?? ''}",
      'lengthInInches':
          "${state.lengthInCentimeters.cmToFeetInches['inches'] ?? ''}",
      'widthInFeet': "${state.widthInCentimeters.cmToFeetInches['feet'] ?? ''}",
      'widthInInches':
          "${state.widthInCentimeters.cmToFeetInches['inches'] ?? ''}",
      'heightInFeet':
          "${state.heightInCentimeters.cmToFeetInches['feet'] ?? ''}",
      'heightInInches':
          "${state.heightInCentimeters.cmToFeetInches['inches'] ?? ''}",
      'weightInLbs': "${state.grossWeightInKilograms.kgToLbs}",
      'weightPerAxleInLbs': "${state.weightPerAxleInKilograms.kgToLbs}",
      'axleCount': "${state.axleCount}",
      'hazardousMaterial': state.hazardousMaterial,
    };
    setHasChanges(false);
  }

  void clearEditState() {
    editState.clear();
    initialState.clear();

    setHasChanges(false);
  }

  void setHasChanges(bool hasChanges) {
    if (state.hasChanges != hasChanges) {
      emit(state.copyWith(hasChanges: hasChanges));
    }
  }

  void toggleAvoidance(key) {
    final Map<String, bool> _avoidance = {...state.avoidance};
    _avoidance[key] = !_avoidance[key]!;
    emit(state.copyWith(avoidance: _avoidance));
  }

  void editTruckSpecs() {
    try {
      if (editState.isNotEmpty) {
        num? updateLengthInCm;
        num? updateWidthInCm;
        num? updateHeightInCm;
        num? updateWeightKgs;
        num? updateWeightPerAxleKgs;
        num? updateAxleCount;
        String? updateHazardousMaterial;

        for (var entry in editState.entries) {
          checkAndCalculateTheFeetAndInchesField(entry, 'length', (value) {
            updateLengthInCm = value;
          });
          checkAndCalculateTheFeetAndInchesField(entry, 'width', (value) {
            updateWidthInCm = value;
          });
          checkAndCalculateTheFeetAndInchesField(entry, 'height', (value) {
            updateHeightInCm = value;
          });

          checkWeightField(entry, 'weight', (value) {
            updateWeightKgs = value;
          });

          checkWeightField(entry, 'weightPerAxle', (value) {
            updateWeightPerAxleKgs = value;
          });

          if (entry.key == 'axleCount') {
            final axleCount = int.tryParse(entry.value);
            updateAxleCount = axleCount;
          }
          if (entry.key == 'hazardousMaterial') {
            updateHazardousMaterial = entry.value;
          }
        }

        emit(
          state.copyWith(
            lengthInCentimeters: updateLengthInCm?.toInt(),
            widthInCentimeters: updateWidthInCm?.toInt(),
            heightInCentimeters: updateHeightInCm?.toInt(),
            grossWeightInKilograms: updateWeightKgs?.toInt(),
            weightPerAxleInKilograms: updateWeightPerAxleKgs?.toInt(),
            axleCount: updateAxleCount?.toInt(),
            hazardousMaterial: updateHazardousMaterial,
          ),
        );
      }
      clearEditState();
    } catch (e) {
      print("Getting error on updating truck specs $e");
    }
  }

  checkWeightField(entry, field, onChange) {
    if (entry.key.contains(field)) {
      final weightLbs = int.tryParse(
        editState['${field}InLbs'] ?? initialState['${field}InLbs'] ?? '',
      );
      if (weightLbs != null) {
        onChange(weightLbs.lbsToKgs);
      }
    }
  }

  checkAndCalculateTheFeetAndInchesField(entry, field, onChange) {
    if (entry.key.contains(field)) {
      final feet = int.tryParse(
        editState['${field}InFeet'] ?? initialState['${field}InFeet'] ?? '',
      );
      final inches = int.tryParse(
        editState['${field}InInches'] ?? initialState['${field}InInches'] ?? '',
      );
      if (feet != null && inches != null) {
        final totalInches = (feet * 12) + inches;
        onChange(totalInches.inchesToCm);
      }
    }
  }
}
