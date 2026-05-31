import 'package:image_picker/image_picker.dart';

/// Serviço de câmera para captura de fotos de evidências.
class CameraService {
  static final _picker = ImagePicker();

  /// Abre a câmera e retorna o caminho do arquivo capturado.
  /// Retorna null se o usuário cancelar.
  static Future<String?> tirarFoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
      preferredCameraDevice: CameraDevice.rear,
    );
    return file?.path;
  }

  /// Retorna true se a câmera está disponível no dispositivo.
  static bool isCameraAvailable() {
    return _picker.supportsImageSource(ImageSource.camera);
  }
}
