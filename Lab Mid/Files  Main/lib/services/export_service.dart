import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/task.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  final _dateFormat = DateFormat('yyyy-MM-dd');

  Future<void> exportToCSV(List<Task> tasks) async {
    final rows = <List<String>>[
      ['Title', 'Description', 'Category', 'Priority', 'Start Date', 'End Date', 'Completed', 'Subtasks'],
    ];

    for (final task in tasks) {
      rows.add([
        task.title,
        task.description,
        task.category.name,
        task.priority.name,
        _dateFormat.format(task.startDate),
        _dateFormat.format(task.endDate),
        task.completed ? 'Yes' : 'No',
        task.subtasks.map((s) => '${s.title}:${s.completed ? "done" : "pending"}').join('; '),
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);

    if (kIsWeb) {
      debugPrint('CSV export not fully supported on web.');
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/nabeel_tasks_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'My Tasks Export');
  }

  Future<void> exportToPDF(List<Task> tasks) async {
    if (kIsWeb) {
      debugPrint('PDF export not fully supported on web.');
      return;
    }

    final doc = pw.Document();
    final rows = <List<String>>[
      ['Title', 'Category', 'Priority', 'Start', 'End', 'Completed'],
      ...tasks.map((t) => [
            t.title,
            t.category.name,
            t.priority.name,
            _dateFormat.format(t.startDate),
            _dateFormat.format(t.endDate),
            t.completed ? 'Yes' : 'No',
          ]),
    ];

    doc.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Tasks Export', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(data: rows),
          ],
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/nabeel_tasks_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await doc.save());
    await Share.shareXFiles([XFile(file.path)], text: 'My Tasks Export (PDF)');
  }

  Future<void> exportToEmail(List<Task> tasks) async {
    if (kIsWeb) {
      debugPrint('Email export not fully supported on web.');
      return;
    }

    final csv = generateCSVString(tasks);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/nabeel_tasks_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Task Export',
      text: 'Here is my task export.',
    );
  }

  String generateCSVString(List<Task> tasks) {
    final rows = <List<String>>[
      ['Title', 'Description', 'Category', 'Priority', 'Start Date', 'End Date', 'Completed'],
    ];

    for (final task in tasks) {
      rows.add([
        task.title,
        task.description,
        task.category.name,
        task.priority.name,
        _dateFormat.format(task.startDate),
        _dateFormat.format(task.endDate),
        task.completed ? 'Yes' : 'No',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }
}
