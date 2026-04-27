class BMIRecord {
  final String id;
  final String date; // ISO timestamp
  final double bmi;
  final String category;
  final double weight;
  final int height;
  final String weightUnit;
  final String heightUnit;

  const BMIRecord({
    required this.id,
    required this.date,
    required this.bmi,
    required this.category,
    required this.weight,
    required this.height,
    required this.weightUnit,
    required this.heightUnit,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'bmi': bmi,
        'category': category,
        'weight': weight,
        'height': height,
        'weightUnit': weightUnit,
        'heightUnit': heightUnit,
      };

  factory BMIRecord.fromJson(Map<String, dynamic> j) => BMIRecord(
        id: j['id'] as String,
        date: j['date'] as String,
        bmi: (j['bmi'] as num).toDouble(),
        category: j['category'] as String,
        weight: (j['weight'] as num).toDouble(),
        height: (j['height'] as num).toInt(),
        weightUnit: j['weightUnit'] as String,
        heightUnit: j['heightUnit'] as String,
      );
}
