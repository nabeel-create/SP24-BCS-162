class UserProfile {
  final String name;
  final int age;
  final String gender; // 'male' | 'female'

  const UserProfile({
    required this.name,
    required this.age,
    required this.gender,
  });

  UserProfile copyWith({String? name, int? age, String? gender}) =>
      UserProfile(
        name: name ?? this.name,
        age: age ?? this.age,
        gender: gender ?? this.gender,
      );

  Map<String, dynamic> toJson() =>
      {'name': name, 'age': age, 'gender': gender};

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        name: (j['name'] ?? '') as String,
        age: ((j['age'] ?? 25) as num).toInt(),
        gender: (j['gender'] ?? 'male') as String,
      );

  static const UserProfile defaults =
      UserProfile(name: '', age: 25, gender: 'male');
}
