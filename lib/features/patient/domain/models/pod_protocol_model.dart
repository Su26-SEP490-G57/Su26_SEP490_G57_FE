import 'package:equatable/equatable.dart';

/// Bác sĩ đã chỉ định chế độ ăn riêng (khi `PodProtocolModel.isCustomized`).
class PrescribingDoctor extends Equatable {
  const PrescribingDoctor({required this.id, required this.fullName});

  factory PrescribingDoctor.fromJson(Map<String, dynamic> json) {
    return PrescribingDoctor(
      id: json['id'] as int,
      fullName: json['fullName'] as String,
    );
  }

  final int id;
  final String fullName;

  @override
  List<Object?> get props => [id, fullName];
}

/// Hướng dẫn chế độ ăn hiện tại của bệnh nhân — có thể là phác đồ chung theo
/// POD (`isCustomized = false`, có `podId`) hoặc chỉ định ăn riêng của bác sĩ
/// (`isCustomized = true`, có `customDietId` + `doctorNotes`/`prescribedByDoctor`).
/// Khớp với `PatientCurrentDietGuidanceResponseDto` / `PodProtocolResponseDto` bên BE.
class PodProtocolModel extends Equatable {
  const PodProtocolModel({
    required this.label,
    required this.recommendedFoods,
    required this.recommendedDrinks,
    this.isCustomized = false,
    this.podId,
    this.operationTypeId,
    this.customDietId,
    this.dietLevel = 0,
    this.forbiddenFoods = const [],
    this.forbiddenDrinks = const [],
    this.upgradeCriteria = const [],
    this.mealsPerDayMin,
    this.mealsPerDayMax,
    this.mealInstruction,
    this.volumePerMealMin,
    this.volumePerMealMax,
    this.volumeInstruction,
    this.doctorNotes,
    this.prescribedByDoctor,
    this.updatedAt,
    this.createdAt,
  });

  factory PodProtocolModel.fromJson(Map<String, dynamic> json) {
    return PodProtocolModel(
      isCustomized: json['isCustomized'] as bool? ?? false,
      podId: json['podId'] as int?,
      operationTypeId: json['operationTypeId'] as int?,
      customDietId: json['customDietId'] as int?,
      label: json['label'] as String,
      dietLevel: json['dietLevel'] as int? ?? 0,
      mealsPerDayMin: json['mealsPerDayMin'] as int?,
      mealsPerDayMax: json['mealsPerDayMax'] as int?,
      mealInstruction: json['mealInstruction'] as String?,
      volumePerMealMin: json['volumePerMealMin'] as int?,
      volumePerMealMax: json['volumePerMealMax'] as int?,
      volumeInstruction: json['volumeInstruction'] as String?,
      doctorNotes: json['doctorNotes'] as String?,
      prescribedByDoctor: json['prescribedByDoctor'] != null
          ? PrescribingDoctor.fromJson(
              json['prescribedByDoctor'] as Map<String, dynamic>,
            )
          : null,
      recommendedFoods:
          (json['recommendedFoods'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      recommendedDrinks:
          (json['recommendedDrinks'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      forbiddenFoods:
          (json['forbiddenFoods'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      forbiddenDrinks:
          (json['forbiddenDrinks'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      upgradeCriteria:
          (json['upgradeCriteria'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  final bool isCustomized;
  final int? podId;
  final int? operationTypeId;
  final int? customDietId;
  final String label;
  final int dietLevel;
  final int? mealsPerDayMin;
  final int? mealsPerDayMax;
  final String? mealInstruction;
  final int? volumePerMealMin;
  final int? volumePerMealMax;
  final String? volumeInstruction;
  final String? doctorNotes;
  final PrescribingDoctor? prescribedByDoctor;
  final List<String> recommendedFoods;
  final List<String> recommendedDrinks;
  final List<String> forbiddenFoods;
  final List<String> forbiddenDrinks;
  final List<String> upgradeCriteria;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
    'isCustomized': isCustomized,
    'podId': podId,
    'operationTypeId': operationTypeId,
    'customDietId': customDietId,
    'label': label,
    'dietLevel': dietLevel,
    'mealsPerDayMin': mealsPerDayMin,
    'mealsPerDayMax': mealsPerDayMax,
    'mealInstruction': mealInstruction,
    'volumePerMealMin': volumePerMealMin,
    'volumePerMealMax': volumePerMealMax,
    'volumeInstruction': volumeInstruction,
    'doctorNotes': doctorNotes,
    'recommendedFoods': recommendedFoods,
    'recommendedDrinks': recommendedDrinks,
    'forbiddenFoods': forbiddenFoods,
    'forbiddenDrinks': forbiddenDrinks,
    'upgradeCriteria': upgradeCriteria,
    'updatedAt': updatedAt?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    isCustomized,
    podId,
    operationTypeId,
    customDietId,
    label,
    dietLevel,
    mealsPerDayMin,
    mealsPerDayMax,
    mealInstruction,
    volumePerMealMin,
    volumePerMealMax,
    volumeInstruction,
    doctorNotes,
    prescribedByDoctor,
    recommendedFoods,
    recommendedDrinks,
    forbiddenFoods,
    forbiddenDrinks,
    upgradeCriteria,
    updatedAt,
    createdAt,
  ];
}
