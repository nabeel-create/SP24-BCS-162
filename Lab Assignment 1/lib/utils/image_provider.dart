import 'package:flutter/material.dart';

import 'image_provider_stub.dart'
    if (dart.library.io) 'image_provider_io.dart'
    if (dart.library.html) 'image_provider_web.dart';

ImageProvider resolveImageProvider(String uri) {
  return buildImageProvider(uri);
}
