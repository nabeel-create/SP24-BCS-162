import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../database/user_database.dart';
import '../models/user.dart';

enum SortField { name, age, createdAt }
enum SortOrder { asc, desc }

class DuplicateUserException implements Exception {
  final String message;

  const DuplicateUserException(this.message);

  @override
  String toString() => message;
}

class UserProvider extends ChangeNotifier {
  UserProvider({UserStore? database})
      : _database = database ?? UserDatabase.instance {
    _loadUsers();
  }

  final UserStore _database;

  List<User> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  SortField _sortField = SortField.createdAt;
  SortOrder _sortOrder = SortOrder.desc;

  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  SortField get sortField => _sortField;
  SortOrder get sortOrder => _sortOrder;

  List<User> get filteredUsers {
    List<User> result = List.from(_users);
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((u) {
        return u.name.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            u.age.toLowerCase().contains(q);
      }).toList();
    }
    result.sort((a, b) {
      int cmp = 0;
      switch (_sortField) {
        case SortField.name:
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case SortField.age:
          cmp = (int.tryParse(a.age) ?? 0).compareTo(int.tryParse(b.age) ?? 0);
          break;
        case SortField.createdAt:
          cmp = a.createdAt.compareTo(b.createdAt);
          break;
      }
      return _sortOrder == SortOrder.asc ? cmp : -cmp;
    });
    return result;
  }

  Future<void> _loadUsers() async {
    try {
      _isLoading = true;
      notifyListeners();
      _users = await _database.getUsers();
    } catch (e) {
      debugPrint('Failed to load users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveUsers() async {
    await _database.replaceUsers(_users);
  }

  String normalizeEmail(String email) => email.trim().toLowerCase();

  bool emailExists(String email, {String? excludingId}) {
    final normalizedEmail = normalizeEmail(email);
    return _users.any((user) {
      if (excludingId != null && user.id == excludingId) {
        return false;
      }
      return normalizeEmail(user.email) == normalizedEmail;
    });
  }

  void _ensureUniqueEmail(String email, {String? excludingId}) {
    if (emailExists(email, excludingId: excludingId)) {
      throw const DuplicateUserException('A user with this email already exists');
    }
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setSortField(SortField field) {
    _sortField = field;
    notifyListeners();
  }

  void setSortOrder(SortOrder order) {
    _sortOrder = order;
    notifyListeners();
  }

  void toggleSortOrder() {
    _sortOrder = _sortOrder == SortOrder.asc ? SortOrder.desc : SortOrder.asc;
    notifyListeners();
  }

  Future<void> addUser({
    required String name,
    required String email,
    required String age,
    String? imageUri,
  }) async {
    _ensureUniqueEmail(email);

    final user = User(
      id: User.generateId(),
      name: name,
      email: normalizeEmail(email),
      age: age,
      imageUri: imageUri,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    _users.add(user);
    await _database.insertUser(user);
    notifyListeners();
  }

  Future<void> updateUser(
    String id, {
    String? name,
    String? email,
    String? age,
    String? imageUri,
    bool clearImage = false,
  }) async {
    final idx = _users.indexWhere((u) => u.id == id);
    if (idx == -1) {
      return;
    }

    final nextEmail = email ?? _users[idx].email;
    _ensureUniqueEmail(nextEmail, excludingId: id);

    final updatedUser = _users[idx].copyWith(
      name: name,
      email: normalizeEmail(nextEmail),
      age: age,
      imageUri: imageUri,
      clearImage: clearImage,
    );
    _users[idx] = updatedUser;
    await _database.updateUser(updatedUser);
    notifyListeners();
  }

  Future<void> deleteUser(String id) async {
    _users.removeWhere((u) => u.id == id);
    await _database.deleteUser(id);
    notifyListeners();
  }

  Future<void> restoreUser(User user, {int? index}) async {
    final nextIndex = index == null || index < 0 || index > _users.length
        ? _users.length
        : index;
    _ensureUniqueEmail(user.email, excludingId: user.id);
    _users.insert(nextIndex, user);
    await _database.insertUser(user);
    notifyListeners();
  }

  int indexOfUser(String id) {
    return _users.indexWhere((u) => u.id == id);
  }

  Future<void> refreshUsers() async {
    await _loadUsers();
  }

  String exportBackup() {
    final data = {
      'version': 1,
      'exportedAt': DateTime.now().millisecondsSinceEpoch,
      'users': _users.map((u) => u.toJson()).toList(),
    };
    return jsonEncode(data);
  }

  Future<int> importBackup(String json) async {
    final data = jsonDecode(json) as Map<String, dynamic>;
    final importedUsers = (data['users'] as List<dynamic>)
        .map((e) => User.fromJson(e as Map<String, dynamic>))
        .toList();
    int added = 0;
    for (final u in importedUsers) {
      final duplicateId = _users.any((x) => x.id == u.id);
      final duplicateEmail = emailExists(u.email);
      if (!duplicateId && !duplicateEmail) {
        _users.add(u.copyWith(email: normalizeEmail(u.email)));
        added++;
      }
    }
    if (added > 0) {
      await _saveUsers();
      notifyListeners();
    }
    return added;
  }
}
