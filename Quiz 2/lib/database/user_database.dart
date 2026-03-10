import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/user.dart';

abstract class UserStore {
  Future<List<User>> getUsers();
  Future<void> insertUser(User user);
  Future<void> updateUser(User user);
  Future<void> deleteUser(String id);
  Future<void> replaceUsers(List<User> users);
}

class UserDatabase implements UserStore {
  UserDatabase._();

  static final UserDatabase instance = UserDatabase._();

  static const String _databaseName = 'profile_vault.db';
  static const String _tableName = 'users';
  static const int _databaseVersion = 2;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_unique ON $_tableName(email)',
          );
        }
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        age TEXT NOT NULL,
        imageUri TEXT,
        createdAt INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX idx_users_email_unique ON $_tableName(email)',
    );
  }

  @override
  Future<List<User>> getUsers() async {
    final db = await database;
    final rows = await db.query(_tableName);
    return rows.map(User.fromJson).toList();
  }

  @override
  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert(
      _tableName,
      user.toJson(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> updateUser(User user) async {
    final db = await database;
    await db.update(
      _tableName,
      user.toJson(),
      where: 'id = ?',
      whereArgs: [user.id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> deleteUser(String id) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> replaceUsers(List<User> users) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(_tableName);
      for (final user in users) {
        await txn.insert(
          _tableName,
          user.toJson(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
    });
  }
}
