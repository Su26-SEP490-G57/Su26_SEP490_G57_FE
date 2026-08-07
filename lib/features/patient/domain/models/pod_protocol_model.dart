import 'package:equatable/equatable.dart';

class PodProtocolModel extends Equatable {
  const PodProtocolModel({
    required this.podId,
    required this.operationTypeId,
    required this.label,
    required this.recommendedFoods,
    required this.recommendedDrinks,
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
    this.updatedAt,
    this.createdAt,
  });

  factory PodProtocolModel.fromJson(Map<String, dynamic> json) {
    return PodProtocolModel(
      podId: json['podId'] as int,
      operationTypeId: json['operationTypeId'] as int,
      label: json['label'] as String,
      dietLevel: (json['dietLevel'] as int?) ?? 0,
      mealsPerDayMin: json['mealsPerDayMin'] as int?,
      mealsPerDayMax: json['mealsPerDayMax'] as int?,
      mealInstruction: json['mealInstruction'] as String?,
      volumePerMealMin: json['volumePerMealMin'] as int?,
      volumePerMealMax: json['volumePerMealMax'] as int?,
      volumeInstruction: json['volumeInstruction'] as String?,
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

  final int podId;
  final int operationTypeId;
  final String label;
  final int dietLevel;
  final int? mealsPerDayMin;
  final int? mealsPerDayMax;
  final String? mealInstruction;
  final int? volumePerMealMin;
  final int? volumePerMealMax;
  final String? volumeInstruction;
  final List<String> recommendedFoods;
  final List<String> recommendedDrinks;
  final List<String> forbiddenFoods;
  final List<String> forbiddenDrinks;
  final List<String> upgradeCriteria;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
    'podId': podId,
    'operationTypeId': operationTypeId,
    'label': label,
    'dietLevel': dietLevel,
    'mealsPerDayMin': mealsPerDayMin,
    'mealsPerDayMax': mealsPerDayMax,
    'mealInstruction': mealInstruction,
    'volumePerMealMin': volumePerMealMin,
    'volumePerMealMax': volumePerMealMax,
    'volumeInstruction': volumeInstruction,
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
    podId,
    operationTypeId,
    label,
    dietLevel,
    mealsPerDayMin,
    mealsPerDayMax,
    mealInstruction,
    volumePerMealMin,
    volumePerMealMax,
    volumeInstruction,
    recommendedFoods,
    recommendedDrinks,
    forbiddenFoods,
    forbiddenDrinks,
    upgradeCriteria,
    updatedAt,
    createdAt,
  ];
}
