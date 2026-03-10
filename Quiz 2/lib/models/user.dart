class User {
  final String id;
  final String name;
  final String email;
  final String age;
  final String? imageUri;
  final int createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    this.imageUri,
    required this.createdAt,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? age,
    String? imageUri,
    int? createdAt,
    bool clearImage = false,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      imageUri: clearImage ? null : (imageUri ?? this.imageUri),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
      'imageUri': imageUri,
      'createdAt': createdAt,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      age: json['age'] as String,
      imageUri: json['imageUri'] as String?,
      createdAt: json['createdAt'] as int,
    );
  }

  static String generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}${(1000 + (9000 * (DateTime.now().microsecondsSinceEpoch % 1000) / 1000)).toInt()}';
  }
}
