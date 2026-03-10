import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/patient.dart';
import '../models/patient_document.dart';
import '../utils/file_storage.dart';
import '../utils/patient_db.dart';

class PatientProvider extends ChangeNotifier {
  PatientProvider() {
    _init();
  }

  final PatientDb _db = PatientDb.instance;
  final List<Patient> _patients = [];
  final List<PatientDocument> _documents = [];
  bool _loading = true;

  List<Patient> get patients => List.unmodifiable(_patients);
  List<PatientDocument> get documents => List.unmodifiable(_documents);
  bool get loading => _loading;

  Patient? getPatient(String id) {
    try {
      return _patients.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<PatientDocument> documentsFor(String patientId) {
    return _documents.where((doc) => doc.patientId == patientId).toList();
  }

  Future<void> _init() async {
    await _db.init();
    await _loadPatients();
  }

  Future<Patient> addPatient(Map<String, String> data) async {
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
    await _db.insertPatient(patient);
    notifyListeners();
    return patient;
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
    await _db.updatePatient(updated);
    notifyListeners();
  }

  Future<void> deletePatient(String id) async {
    final patient = getPatient(id);
    final docsToDelete = _documents.where((doc) => doc.patientId == id).toList();
    _patients.removeWhere((p) => p.id == id);
    _documents.removeWhere((doc) => doc.patientId == id);
    await _db.deletePatient(id);
    if (patient != null) {
      await FileStorage.deleteIfExists(patient.imageUri);
    }
    for (final doc in docsToDelete) {
      await FileStorage.deleteIfExists(doc.path);
    }
    notifyListeners();
  }

  Future<void> addDocument({
    required String patientId,
    required String name,
    required String type,
    required String path,
    required int size,
  }) async {
    final now = DateTime.now().toIso8601String();
    final id = '${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(999999)}';
    final document = PatientDocument(
      id: id,
      patientId: patientId,
      name: name,
      type: type,
      path: path,
      size: size,
      addedAt: now,
    );
    _documents.insert(0, document);
    await _db.insertDocument(document);
    notifyListeners();
  }

  Future<void> deleteDocument(String id) async {
    final docIndex = _documents.indexWhere((doc) => doc.id == id);
    if (docIndex == -1) return;
    final doc = _documents[docIndex];
    _documents.removeAt(docIndex);
    await _db.deleteDocument(id);
    await FileStorage.deleteIfExists(doc.path);
    notifyListeners();
  }

  Future<void> _loadPatients() async {
    try {
      final loaded = await _db.getPatients();
      final docs = await _db.getDocuments();
      _patients
        ..clear()
        ..addAll(loaded);
      _documents
        ..clear()
        ..addAll(docs);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load patients: $e');
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
