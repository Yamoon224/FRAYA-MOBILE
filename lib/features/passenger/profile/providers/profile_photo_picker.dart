import 'package:image_picker/image_picker.dart';

class ProfilePhotoPicker {
  ProfilePhotoPicker({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  Future<XFile?> pickFromCamera() {
    return _imagePicker.pickImage(source: ImageSource.camera);
  }

  Future<XFile?> pickFromGallery() {
    return _imagePicker.pickImage(source: ImageSource.gallery);
  }
}
