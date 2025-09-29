import 'package:equatable/equatable.dart';
import 'package:here_sdk/transport.dart';
import 'package:ommo/utils/extension/num_extension.dart';

class TruckSpecificationState extends Equatable {
  final int heightInCentimeters;
  final int widthInCentimeters;
  final int lengthInCentimeters;
  final int grossWeightInKilograms;
  final int weightPerAxleInKilograms;
  final int axleCount;
  final TruckType truckType;
  final int trailerCount;
  final String materialType;
  final bool hasChanges;
  final Map<String, bool> avoidance;

  const TruckSpecificationState({
    this.grossWeightInKilograms = 17000,
    this.heightInCentimeters = 3 * 100,
    this.widthInCentimeters = 4 * 100,
    this.lengthInCentimeters = 8 * 100,
    this.weightPerAxleInKilograms = 2 * 1000,
    this.axleCount = 4,
    this.trailerCount = 2,
    this.truckType = TruckType.straight,
    this.materialType = "Flammable",
    this.hasChanges = false,
    this.avoidance = const {
      'highways': false,
      'tolls': false,
      'ferries': false,
      'tunnels': false,
      'unpaved_roads': false,
    },
  });

  Map<String, String> get truckInfo => {
    "Height": heightInCentimeters.cmtoFeetInchesFormattedString,
    "Width": widthInCentimeters.cmtoFeetInchesFormattedString,
    "Length": lengthInCentimeters.cmtoFeetInchesFormattedString,
    "Total Weight": grossWeightInKilograms.kgToLbsFormattedString,
    "Axle Count": axleCount.toString(),
    "Weight per Axle Group": weightPerAxleInKilograms.kgToLbsFormattedString,
    "Hazardous Materials": materialType,
  };

  TruckSpecificationState copyWith({
    int? grossWeightInKilograms,
    int? heightInCentimeters,
    int? widthInCentimeters,
    int? lengthInCentimeters,
    int? weightPerAxleInKilograms,
    int? axleCount,
    int? trailerCount,
    TruckType? truckType,
    String? materialType,
    bool? hasChanges,
    Map<String, bool>? avoidance,
  }) {
    return TruckSpecificationState(
      grossWeightInKilograms:
          grossWeightInKilograms ?? this.grossWeightInKilograms,
      heightInCentimeters: heightInCentimeters ?? this.heightInCentimeters,
      widthInCentimeters: widthInCentimeters ?? this.widthInCentimeters,
      lengthInCentimeters: lengthInCentimeters ?? this.lengthInCentimeters,
      weightPerAxleInKilograms:
          weightPerAxleInKilograms ?? this.weightPerAxleInKilograms,
      axleCount: axleCount ?? this.axleCount,
      trailerCount: trailerCount ?? this.trailerCount,
      truckType: truckType ?? this.truckType,
      materialType: materialType ?? this.materialType,
      hasChanges: hasChanges ?? this.hasChanges,
      avoidance: avoidance ?? this.avoidance,
    );
  }

  @override
  List<Object?> get props => [
    grossWeightInKilograms,
    heightInCentimeters,
    widthInCentimeters,
    lengthInCentimeters,
    weightPerAxleInKilograms,
    axleCount,
    trailerCount,
    truckType,
    materialType,
    hasChanges,
    avoidance,
  ];
}
