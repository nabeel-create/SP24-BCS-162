import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StoredFile {
  StoredFile({
    required this.name,
    required this.path,
    required this.type,
    required this.size,
  });

  final String name;
  final String path;
  final String type;
  final int size;
}

class FileStorage {
  static Future<String> saveImage(XFile file) async {
    final dir = await _ensureDir('patient_images');
    final ext = p.extension(file.path);
    final filename = 'img_${DateTime.now().millisecondsSinceEpoch}$ext';
    final target = p.join(dir.path, filename);
    final saved = await File(file.path).copy(target);
    return saved.path;
  }

  static Future<StoredFile?> saveDocument(PlatformFile file) async {
    if (file.path == null) return null;
    final dir = await _ensureDir('patient_docs');
    final ext = p.extension(file.path!);
    final filename = 'doc_${DateTime.now().millisecondsSinceEpoch}$ext';
    final target = p.join(dir.path, filename);
    final saved = await File(file.path!).copy(target);
    final type = ext.isNotEmpty ? ext.replaceFirst('.', '').toUpperCase() : 'FILE';
    return StoredFile(
      name: file.name,
      path: saved.path,
      type: type,
      size: file.size,
    );
  }

  static Future<void> deleteIfExists(String path) async {
    if (path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  static Future<Directory> _ensureDir(String name) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, name));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}

