library;

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../domain/models/driver_kyc_document_file.dart';

typedef PickFilesCallback =
    Future<FilePickerResult?> Function({
      required bool allowMultiple,
      FileType type,
      List<String>? allowedExtensions,
    });

class DriverKycDocumentPicker {
  DriverKycDocumentPicker({
    ImagePicker? imagePicker,
    PickFilesCallback? pickFiles,
  }) : _imagePicker = imagePicker ?? ImagePicker(),
       _pickFiles = pickFiles ?? FilePicker.pickFiles;

  final ImagePicker _imagePicker;
  final PickFilesCallback _pickFiles;

  Future<DriverKycDocumentFile?> pick(DriverKycDocumentSource source) async {
    switch (source) {
      case DriverKycDocumentSource.camera:
        return _pickImage(ImageSource.camera, source);
      case DriverKycDocumentSource.galleryImage:
        return _pickImage(ImageSource.gallery, source);
      case DriverKycDocumentSource.pdfFile:
        return _pickPdf();
    }
  }

  Future<DriverKycDocumentFile?> _pickImage(
    ImageSource source,
    DriverKycDocumentSource documentSource,
  ) async {
    final file = await _imagePicker.pickImage(source: source);
    if (file == null) {
      return null;
    }
    return DriverKycDocumentFile.fromPath(
      path: file.path,
      fileName: file.name,
      source: documentSource,
    );
  }

  Future<DriverKycDocumentFile?> _pickPdf() async {
    final result = await _pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    final files = result?.files;
    final file = files == null || files.isEmpty ? null : files.first;
    final path = file?.path;
    if (file == null || path == null) {
      return null;
    }
    return DriverKycDocumentFile.fromPath(
      path: path,
      fileName: file.name,
      source: DriverKycDocumentSource.pdfFile,
    );
  }
}
