import 'package:equatable/equatable.dart';

class PodProtocolModel extends Equatable {
  const PodProtocolModel({
    required this.podId,
    required this.operationTypeId,
    required this.label,
    this.mealsPerDayMin,
    this.mealsPerDayMax,
    this.mealInstruction,
    this.volumePerMealMin,
    this.volumePerMealMax,
    this.volumeInstruction,
    required this.recommendedFoods,
    required this.recommendedDrinks,
    this.updatedAt,
    this.createdAt,
  });

  final int podId;
  final int operationTypeId;
  final String label;
  final int? mealsPerDayMin;
  final int? mealsPerDayMax;
  final String? mealInstruction;
  final int? volumePerMealMin;
  final int? volumePerMealMax;
  final String? volumeInstruction;
  final List<String> recommendedFoods;
  final List<String> recommendedDrinks;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  factory PodProtocolModel.fromJson(Map<String, dynamic> json) {
    return PodProtocolModel(
      podId: json['podId'] as int,
      operationTypeId: json['operationTypeId'] as int,
      label: json['label'] as String,
      mealsPerDayMin: json['mealsPerDayMin'] as int?,
      mealsPerDayMax: json['mealsPerDayMax'] as int?,
      mealInstruction: json['mealInstruction'] as String?,
      volumePerMealMin: json['volumePerMealMin'] as int?,
      volumePerMealMax: json['volumePerMealMax'] as int?,
      volumeInstruction: json['volumeInstruction'] as String?,
      recommendedFoods: (json['recommendedFoods'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      recommendedDrinks: (json['recommendedDrinks'] as List<dynamic>?)
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

  Map<String, dynamic> toJson() => {
        'podId': podId,
        'operationTypeId': operationTypeId,
        'label': label,
        'mealsPerDayMin': mealsPerDayMin,
        'mealsPerDayMax': mealsPerDayMax,
        'mealInstruction': mealInstruction,
        'volumePerMealMin': volumePerMealMin,
        'volumePerMealMax': volumePerMealMax,
        'volumeInstruction': volumeInstruction,
        'recommendedFoods': recommendedFoods,
        'recommendedDrinks': recommendedDrinks,
        'updatedAt': updatedAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        podId,
        operationTypeId,
        label,
        mealsPerDayMin,
        mealsPerDayMax,
        mealInstruction,
        volumePerMealMin,
        volumePerMealMax,
        volumeInstruction,
        recommendedFoods,
        recommendedDrinks,
        updatedAt,
        createdAt,
      ];
}
