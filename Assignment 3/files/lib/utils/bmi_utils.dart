import 'package:flutter/material.dart';

import '../constants/colors.dart';

String getBMICategory(double bmi) {
  if (bmi < 18.5) return 'Underweight';
  if (bmi < 25) return 'Normal';
  if (bmi < 30) return 'Overweight';
  return 'Obese';
}

String getBMIShortLabel(double bmi) {
  if (bmi < 18.5) return 'Under';
  if (bmi < 25) return 'Normal';
  if (bmi < 30) return 'Over';
  return 'Obese';
}

Color getBMIColor(double bmi) {
  return getBMIColorForPalette(AppPalette.dark, bmi);
}

Color getBMIColorForPalette(AppPalette palette, double bmi) {
  if (bmi < 18.5) return palette.underweight;
  if (bmi < 25) return palette.normal;
  if (bmi < 30) return palette.overweight;
  return palette.obese;
}

double calculateBMI(double weightKg, int heightCm) {
  if (heightCm <= 0 || weightKg <= 0) return 0;
  final hM = heightCm / 100.0;
  return ((weightKg / (hM * hM)) * 10).round() / 10;
}

class IdealWeight {
  final double min;
  final double max;
  const IdealWeight(this.min, this.max);
}

IdealWeight getIdealWeight(int heightCm) {
  final hM = heightCm / 100.0;
  return IdealWeight(
    (18.5 * hM * hM * 10).round() / 10,
    (24.9 * hM * hM * 10).round() / 10,
  );
}

int getCalories(double kg, int cm, int age, String gender) {
  final bmr = gender == 'male'
      ? 10 * kg + 6.25 * cm - 5 * age + 5
      : 10 * kg + 6.25 * cm - 5 * age - 161;
  return (bmr * 1.55).round();
}

String getBMIMessage(double bmi) {
  switch (getBMICategory(bmi)) {
    case 'Underweight':
      return 'Consider gaining weight through nutritious foods and strength training.';
    case 'Normal':
      return 'You are in a healthy range. Keep up the great lifestyle!';
    case 'Overweight':
      return 'Consider moderating calorie intake and increasing physical activity.';
    case 'Obese':
      return 'Consult a healthcare professional for personalized weight management guidance.';
  }
  return '';
}
