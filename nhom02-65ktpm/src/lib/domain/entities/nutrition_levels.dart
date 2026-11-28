import '../enums.dart';

/// Bộ mức độ đánh giá của một món (thấp/vừa/cao), KHÔNG có số calo.
class NutritionLevels {
  const NutritionLevels({
    this.sugar = Level.medium,
    this.fat = Level.medium,
    this.carb = Level.medium,
    this.veg = Level.medium,
    this.protein = Level.medium,
    this.energy = Level.medium,
  });

  final Level sugar;
  final Level fat;
  final Level carb;
  final Level veg;
  final Level protein;
  final Level energy;

  Level of(LevelAttribute attribute) => switch (attribute) {
        LevelAttribute.sugar => sugar,
        LevelAttribute.fat => fat,
        LevelAttribute.carb => carb,
        LevelAttribute.veg => veg,
        LevelAttribute.protein => protein,
        LevelAttribute.energy => energy,
      };

  NutritionLevels withLevel(LevelAttribute attribute, Level level) {
    return NutritionLevels(
      sugar: attribute == LevelAttribute.sugar ? level : sugar,
      fat: attribute == LevelAttribute.fat ? level : fat,
      carb: attribute == LevelAttribute.carb ? level : carb,
      veg: attribute == LevelAttribute.veg ? level : veg,
      protein: attribute == LevelAttribute.protein ? level : protein,
      energy: attribute == LevelAttribute.energy ? level : energy,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NutritionLevels &&
      other.sugar == sugar &&
      other.fat == fat &&
      other.carb == carb &&
      other.veg == veg &&
      other.protein == protein &&
      other.energy == energy;

  @override
  int get hashCode => Object.hash(sugar, fat, carb, veg, protein, energy);

  @override
  String toString() =>
      'Levels(sugar:${sugar.value}, fat:${fat.value}, carb:${carb.value}, '
      'veg:${veg.value}, protein:${protein.value}, energy:${energy.value})';
}
