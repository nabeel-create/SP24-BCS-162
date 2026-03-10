import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/patient.dart';
import '../models/patient_document.dart';

class PatientDb {
  PatientDb._();

  static final PatientDb instance = PatientDb._();
  static const _dbName = 'doctor_app.db';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _open();
    return _database!;
  }

  Future<void> init() async {
    await database;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE patients (
            id TEXT PRIMARY KEY,
            name TEXT,
            age TEXT,
            phone TEXT,
            email TEXT,
            diagnosis TEXT,
            notes TEXT,
            bloodType TEXT,
            gender TEXT,
            address TEXT,
            imageUri TEXT,
            allergies TEXT,
            medications TEXT,
            emergencyContact TEXT,
            emergencyPhone TEXT,
            weight TEXT,
            height TEXT,
            status TEXT,
            appointmentDate TEXT,
            createdAt TEXT,
            updatedAt TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE documents (
            id TEXT PRIMARY KEY,
            patientId TEXT,
            name TEXT,
            type TEXT,
            path TEXT,
            size INTEGER,
            addedAt TEXT
          )
        ''');
      },
    );
  }

  Future<List<Patient>> getPatients() async {
    final db = await database;
    final rows = await db.query('patients', orderBy: 'createdAt DESC');
    return rows.map(Patient.fromMap).toList();
  }

  Future<void> insertPatient(Patient patient) async {
    final db = await database;
    await db.insert('patients', patient.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updatePatient(Patient patient) async {
    final db = await database;
    await db.update('patients', patient.toMap(), where: 'id = ?', whereArgs: [patient.id]);
  }

  Future<void> deletePatient(String id) async {
    final db = await database;
    await db.delete('patients', where: 'id = ?', whereArgs: [id]);
    await db.delete('documents', where: 'patientId = ?', whereArgs: [id]);
  }

  Future<List<PatientDocument>> getDocuments() async {
    final db = await database;
    final rows = await db.query('documents', orderBy: 'addedAt DESC');
    return rows.map(PatientDocument.fromMap).toList();
  }

  Future<List<PatientDocument>> getDocumentsForPatient(String patientId) async {
    final db = await database;
    final rows = await db.query(
      'documents',
      where: 'patientId = ?',
      whereArgs: [patientId],
      orderBy: 'addedAt DESC',
    );
    return rows.map(PatientDocument.fromMap).toList();
  }

  Future<void> insertDocument(PatientDocument document) async {
    final db = await database;
    await db.insert('documents', document.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteDocument(String id) async {
    final db = await database;
    await db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }
}

