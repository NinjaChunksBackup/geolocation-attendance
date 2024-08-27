import 'package:camera/camera.dart';

class CameraUtils {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _cameraController!.initialize();
  }

  // Add other camera-related methods here
}
