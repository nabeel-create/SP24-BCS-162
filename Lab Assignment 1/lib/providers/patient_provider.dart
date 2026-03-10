import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/patient.dart';

class PatientProvider extends ChangeNotifier {
  static const _storageKey = 'doctor_app_patients_v2';

  PatientProvider() {
    _loadPatients();
  }

  final List<Patient> _patients = [];
  bool _loading = true;

  List<Patient> get patients => List.unmodifiable(_patients);
  bool get loading => _loading;

  Patient? getPatient(String id) {
    try {
      return _patients.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addPatient(Map<String, String> data) async {
    final now = DateTime.now().toIso8601String();
    final id = '${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(999999)}';
    final patient = Patient(
      id: id,
      name: data['name'] ?? '',
      age: data['age'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      diagnosis: data['diagnosis'] ?? '',
      notes: data['notes'] ?? '',
      bloodType: data['bloodType'] ?? '',
      gender: data['gender'] ?? '',
      address: data['address'] ?? '',
      imageUri: data['imageUri'] ?? '',
      allergies: data['allergies'] ?? '',
      medications: data['medications'] ?? '',
      emergencyContact: data['emergencyContact'] ?? '',
      emergencyPhone: data['emergencyPhone'] ?? '',
      weight: data['weight'] ?? '',
      height: data['height'] ?? '',
      status: data['status'] ?? 'Active',
      appointmentDate: data['appointmentDate'] ?? '',
      createdAt: now,
      updatedAt: now,
    );

    _patients.insert(0, patient);
    await _savePatients();
    notifyListeners();
  }

  Future<void> updatePatient(String id, Map<String, String> data) async {
    final index = _patients.indexWhere((p) => p.id == id);
    if (index == -1) return;
    final updated = _patients[index].copyWith(
      name: data['name'],
      age: data['age'],
      phone: data['phone'],
      email: data['email'],
      diagnosis: data['diagnosis'],
      notes: data['notes'],
      bloodType: data['bloodType'],
      gender: data['gender'],
      address: data['address'],
      imageUri: data['imageUri'],
      allergies: data['allergies'],
      medications: data['medications'],
      emergencyContact: data['emergencyContact'],
      emergencyPhone: data['emergencyPhone'],
      weight: data['weight'],
      height: data['height'],
      status: data['status'],
      appointmentDate: data['appointmentDate'],
      updatedAt: DateTime.now().toIso8601String(),
    );
    _patients[index] = updated;
    await _savePatients();
    notifyListeners();
  }

  Future<void> deletePatient(String id) async {
    _patients.removeWhere((p) => p.id == id);
    await _savePatients();
    notifyListeners();
  }

  Future<void> _loadPatients() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _patients
          ..clear()
          ..addAll(decoded.map((e) => Patient.fromJson(e as Map<String, dynamic>)));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load patients: $e');
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _savePatients() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(_patients.map((p) => p.toJson()).toList());
      await prefs.setString(_storageKey, data);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save patients: $e');
      }
    }
  }
}

