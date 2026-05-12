import 'package:flutter/foundation.dart';

import '../models/submission.dart';
import '../services/supabase_credentials.dart';
import '../services/supabase_service.dart';

class SubmissionStore extends ChangeNotifier {
  SubmissionStore()
    : config = const SupabaseConfig(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      ) {
    if (config.isReady) {
      refetch();
    } else {
      loading = false;
    }
  }

  SupabaseConfig config;
  List<Submission> submissions = [];
  bool loading = true;
  bool saving = false;
  String? deletingId;
  String? error;

  SupabaseService get _service => SupabaseService(config);

  Future<void> refetch() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      submissions = await _service.fetchSubmissions();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> createEntry(Submission input) async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      final created = await _service.createSubmission(input);
      submissions = [created, ...submissions];
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> updateEntry(String id, Submission input) async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      final updated = await _service.updateSubmission(id, input);
      submissions = submissions
          .map((item) => item.id == id ? updated : item)
          .toList();
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> deleteEntry(String id) async {
    deletingId = id;
    notifyListeners();
    try {
      await _service.deleteSubmission(id);
      submissions = submissions.where((item) => item.id != id).toList();
    } finally {
      deletingId = null;
      notifyListeners();
    }
  }

  Submission? findById(String id) {
    for (final submission in submissions) {
      if (submission.id == id) return submission;
    }
    return null;
  }
}
