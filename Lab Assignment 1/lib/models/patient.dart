class Patient {
  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.phone,
    required this.email,
    required this.diagnosis,
    required this.notes,
    required this.bloodType,
    required this.gender,
    required this.address,
    required this.imageUri,
    required this.allergies,
    required this.medications,
    required this.emergencyContact,
    required this.emergencyPhone,
    required this.weight,
    required this.height,
    required this.status,
    required this.appointmentDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String age;
  final String phone;
  final String email;
  final String diagnosis;
  final String notes;
  final String bloodType;
  final String gender;
  final String address;
  final String imageUri;
  final String allergies;
  final String medications;
  final String emergencyContact;
  final String emergencyPhone;
  final String weight;
  final String height;
  final String status;
  final String appointmentDate;
  final String createdAt;
  final String updatedAt;

  Patient copyWith({
    String? name,
    String? age,
    String? phone,
    String? email,
    String? diagnosis,
    String? notes,
    String? bloodType,
    String? gender,
    String? address,
    String? imageUri,
    String? allergies,
    String? medications,
    String? emergencyContact,
    String? emergencyPhone,
    String? weight,
    String? height,
    String? status,
    String? appointmentDate,
    String? createdAt,
    String? updatedAt,
  }) {
    return Patient(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      diagnosis: diagnosis ?? this.diagnosis,
      notes: notes ?? this.notes,
      bloodType: bloodType ?? this.bloodType,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      imageUri: imageUri ?? this.imageUri,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      status: status ?? this.status,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] as String,
      name: (map['name'] ?? '') as String,
      age: (map['age'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      diagnosis: (map['diagnosis'] ?? '') as String,
      notes: (map['notes'] ?? '') as String,
      bloodType: (map['bloodType'] ?? '') as String,
      gender: (map['gender'] ?? '') as String,
      address: (map['address'] ?? '') as String,
      imageUri: (map['imageUri'] ?? '') as String,
      allergies: (map['allergies'] ?? '') as String,
      medications: (map['medications'] ?? '') as String,
      emergencyContact: (map['emergencyContact'] ?? '') as String,
      emergencyPhone: (map['emergencyPhone'] ?? '') as String,
      weight: (map['weight'] ?? '') as String,
      height: (map['height'] ?? '') as String,
      status: (map['status'] ?? 'Active') as String,
      appointmentDate: (map['appointmentDate'] ?? '') as String,
      createdAt: (map['createdAt'] ?? '') as String,
      updatedAt: (map['updatedAt'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'phone': phone,
      'email': email,
      'diagnosis': diagnosis,
      'notes': notes,
      'bloodType': bloodType,
      'gender': gender,
      'address': address,
      'imageUri': imageUri,
      'allergies': allergies,
      'medications': medications,
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
      'weight': weight,
      'height': height,
      'status': status,
      'appointmentDate': appointmentDate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String,
      name: (json['name'] ?? '') as String,
      age: (json['age'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      diagnosis: (json['diagnosis'] ?? '') as String,
      notes: (json['notes'] ?? '') as String,
      bloodType: (json['bloodType'] ?? '') as String,
      gender: (json['gender'] ?? '') as String,
      address: (json['address'] ?? '') as String,
      imageUri: (json['imageUri'] ?? '') as String,
      allergies: (json['allergies'] ?? '') as String,
      medications: (json['medications'] ?? '') as String,
      emergencyContact: (json['emergencyContact'] ?? '') as String,
      emergencyPhone: (json['emergencyPhone'] ?? '') as String,
      weight: (json['weight'] ?? '') as String,
      height: (json['height'] ?? '') as String,
      status: (json['status'] ?? 'Active') as String,
      appointmentDate: (json['appointmentDate'] ?? '') as String,
      createdAt: (json['createdAt'] ?? '') as String,
      updatedAt: (json['updatedAt'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }
}

