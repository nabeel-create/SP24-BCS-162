import 'dart:io';

import 'package:flutter/material.dart';

ImageProvider buildImageProvider(String uri) {
  if (uri.startsWith('http')) {
    return NetworkImage(uri);
  }
  return FileImage(File(uri));
}
