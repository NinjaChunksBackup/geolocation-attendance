import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionUtils {
  FaceDetector? _faceDetector;

  void initializeFaceDetector() {
    _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
      enableClassification: true,
      minFaceSize: 0.1,
    ));
  }

  Future<List<Face>> processImage(InputImage inputImage) async {
    return await _faceDetector!.processImage(inputImage);
  }

  // Add other face detection-related methods here
}
