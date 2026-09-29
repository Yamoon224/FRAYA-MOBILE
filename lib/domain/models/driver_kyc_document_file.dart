library;

enum DriverKycDocumentSource { camera, galleryImage, pdfFile }

class DriverKycDocumentFile {
  const DriverKycDocumentFile({
    required this.path,
    required this.fileName,
    required this.mimeType,
    required this.source,
  });

  final String path;
  final String fileName;
  final String mimeType;
  final DriverKycDocumentSource source;

  bool get isPdf => mimeType == 'application/pdf';

  static DriverKycDocumentFile? fromPath({
    required String path,
    required String fileName,
    required DriverKycDocumentSource source,
  }) {
    final mimeType = resolveMimeType(path);
    if (mimeType == null) {
      return null;
    }
    return DriverKycDocumentFile(
      path: path,
      fileName: fileName,
      mimeType: mimeType,
      source: source,
    );
  }

  static bool isSupported(String path) => resolveMimeType(path) != null;

  static String? resolveMimeType(String path) {
    final normalizedPath = path.trim().toLowerCase();
    if (normalizedPath.endsWith('.jpg') || normalizedPath.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (normalizedPath.endsWith('.png')) {
      return 'image/png';
    }
    if (normalizedPath.endsWith('.pdf')) {
      return 'application/pdf';
    }
    return null;
  }
}
