library;

import 'package:flutter_image_compress/flutter_image_compress.dart';

abstract interface class DriverDocumentImageCompressor {
  Future<void> compress({
    required String sourcePath,
    required String targetPath,
    required int quality,
    required int minimumDimension,
  });
}

class NativeDriverDocumentImageCompressor
    implements DriverDocumentImageCompressor {
  const NativeDriverDocumentImageCompressor();

  @override
  Future<void> compress({
    required String sourcePath,
    required String targetPath,
    required int quality,
    required int minimumDimension,
  }) async {
    await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      targetPath,
      quality: quality,
      minWidth: minimumDimension,
      minHeight: minimumDimension,
      format: CompressFormat.jpeg,
      autoCorrectionAngle: true,
      keepExif: false,
    );
  }
}
