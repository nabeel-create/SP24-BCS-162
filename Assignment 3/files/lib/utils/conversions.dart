// Height conversions (base unit: cm)
double cmToM(int cm) => (cm / 100 * 100).round() / 100;
int mToCm(double m) => (m * 100).round();

class FtIn {
  final int feet;
  final int inches;
  const FtIn(this.feet, this.inches);
}

FtIn cmToFtIn(int cm) {
  final totalIn = cm / 2.54;
  return FtIn((totalIn / 12).floor(), (totalIn % 12).round());
}

int ftInToCm(int feet, int inches) =>
    ((feet * 12 + inches) * 2.54).round();

double cmToFt(int cm) => (cm / 30.48 * 10).round() / 10;
int ftToCm(double ft) => (ft * 30.48).round();

// Weight conversions (base unit: kg)
double kgToLbs(double kg) => (kg * 2.2046 * 10).round() / 10;
double lbsToKg(double lbs) => (lbs / 2.2046 * 10).round() / 10;
double kgToSt(double kg) => (kg / 6.35029 * 10).round() / 10;
double stToKg(double st) => (st * 6.35029 * 10).round() / 10;
