import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StartWorkingHourScreen extends StatefulWidget {
  final bool isOffsite;
  final Map<String, dynamic>? offsiteLocation;

  StartWorkingHourScreen({required this.isOffsite, this.offsiteLocation});

  @override
  _StartWorkingHourScreenState createState() => _StartWorkingHourScreenState();
}

class _StartWorkingHourScreenState extends State<StartWorkingHourScreen> {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  String _locationInfo = 'Detecting location...';
  String _currentTime = '';
  bool _isWithinRange = false;
  Timer? _locationTimer;
  Timer? _photoTimer;
  FaceDetector? _faceDetector;
  bool _isFaceDetected = false;
  DateTime? _workStartTime;
  Timer? _workTimer;

  bool _showFaceDetectedMessage = false;
  Timer? _faceDetectedTimer;

  final Color _primaryColor = Colors.blue[700]!;
  final Color _accentColor = Colors.blue[300]!;
  final Color _backgroundColor = Colors.grey[100]!;
  final Color _textColor = Colors.grey[800]!;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _updateTime();
    _startLocationTracking();
    _initializeFaceDetector();
    _initializeNotifications();
    Workmanager().initialize(callbackDispatcher);
    _checkWorkStatus();
  }

  Future<void> _initializeCamera() async {
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
    if (mounted) {
      setState(() {});
    }
  }

  void _initializeFaceDetector() {
    _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
      enableClassification: true,
      minFaceSize: 0.1,
    ));
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _startLocationTracking() {
    _locationTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _checkLocation();
    });
    _checkLocation(); // Initial check
  }

  Future<void> _checkWorkStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? startTime = prefs.getInt('workStartTime');
    if (startTime != null) {
      setState(() {
        _workStartTime = DateTime.fromMillisecondsSinceEpoch(startTime);
      });
      _showNotification();
      _startWorkTimer();
      Navigator.pop(context, true); // Return to home screen
    }
  }

  void _startWork() async {
    setState(() {
      _workStartTime = DateTime.now();
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('workStartTime', _workStartTime!.millisecondsSinceEpoch);
    _showNotification();
    _startWorkTimer();
    Workmanager().registerPeriodicTask(
      "updateWorkTimer",
      "updateWorkTimer",
      frequency: Duration(minutes: 15),
    );
    Navigator.pop(context, true); // Return to home screen
  }

  void _stopWork() async {
    setState(() {
      _workStartTime = null;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('workStartTime');
    _workTimer?.cancel();
    flutterLocalNotificationsPlugin.cancel(0);
    Workmanager().cancelByUniqueName("updateWorkTimer");
  }

  Future<void> _checkLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (widget.isOffsite && widget.offsiteLocation != null) {
        double distance = _calculateDistance(
          position.latitude,
          position.longitude,
          widget.offsiteLocation!['latitude'],
          widget.offsiteLocation!['longitude'],
        );

        bool newIsWithinRange = distance <= 200;
        if (_isWithinRange != newIsWithinRange) {
          setState(() {
            _isWithinRange = newIsWithinRange;
          });
          if (_isWithinRange) {
            _startPhotoCapture();
          } else {
            _stopPhotoCapture();
          }
        }

        setState(() {
          _locationInfo =
              '${widget.offsiteLocation!['name']} - Distance: ${distance.toStringAsFixed(2)}m';
        });
      } else {
        setState(() {
          _isWithinRange = true;
          _locationInfo =
              'Lat: ${position.latitude}, Long: ${position.longitude}';
        });
        _startPhotoCapture();
      }
    } catch (e) {
      setState(() {
        _locationInfo = 'Error detecting location';
        _isWithinRange = false;
      });
      _stopPhotoCapture();
    }
  }

  void _pauseWork() {
    _showPausedNotification();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('workPausedTime', DateTime.now().millisecondsSinceEpoch);
    });
  }

  void _resumeWork() {
    _showResumedNotification();
    SharedPreferences.getInstance().then((prefs) {
      int? pausedTime = prefs.getInt('workPausedTime');
      if (pausedTime != null && _workStartTime != null) {
        int pausedDuration = DateTime.now().millisecondsSinceEpoch - pausedTime;
        _workStartTime =
            _workStartTime!.add(Duration(milliseconds: pausedDuration));
        prefs.setInt('workStartTime', _workStartTime!.millisecondsSinceEpoch);
      }
    });
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; // 2 * R; R = 6371 km
  }

  void _startPhotoCapture() {
    if (_photoTimer == null) {
      _photoTimer = Timer.periodic(Duration(seconds: 5), (_) {
        _captureAndAnalyzePhoto();
      });
    }
  }

  void _stopPhotoCapture() {
    _photoTimer?.cancel();
    _photoTimer = null;
    setState(() {
      _isFaceDetected = false;
      _showFaceDetectedMessage = false;
    });
  }

  Future<void> _captureAndAnalyzePhoto() async {
    try {
      await _initializeControllerFuture;
      final image = await _cameraController!.takePicture();

      final inputImage = InputImage.fromFilePath(image.path);
      final List<Face> faces = await _faceDetector!.processImage(inputImage);

      setState(() {
        _isFaceDetected = faces.isNotEmpty;
        if (_isFaceDetected) {
          _showFaceDetectedMessage = true;
          _faceDetectedTimer?.cancel();
          _faceDetectedTimer = Timer(Duration(seconds: 1), () {
            if (_isWithinRange && _workStartTime == null) {
              _startWork();
            }
          });
        } else {
          _showFaceDetectedMessage = false;
        }
      });

      if ((!_isFaceDetected || !_isWithinRange) && _workStartTime != null) {
        _stopWork();
      }
    } catch (e) {
      print('Error capturing or analyzing photo: $e');
    }
  }

  void _startWorkTimer() {
    _workTimer = Timer.periodic(Duration(seconds: 1), (_) {
      _updateNotification();
    });
  }

  void _showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'work_timer_channel',
      'Work Timer',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Work Timer',
      'Working time: 00:00:00',
      platformChannelSpecifics,
    );
  }

  void _updateNotification() {
    if (_workStartTime != null) {
      Duration workDuration = DateTime.now().difference(_workStartTime!);
      String formattedDuration = _formatDuration(workDuration);
      flutterLocalNotificationsPlugin.show(
        0,
        'Work Timer',
        'Working time: $formattedDuration',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'work_timer_channel',
            'Work Timer',
            importance: Importance.max,
            priority: Priority.high,
            ongoing: true,
            autoCancel: false,
          ),
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    });
    Future.delayed(Duration(minutes: 1), _updateTime);
  }

  void _showPausedNotification() {
    flutterLocalNotificationsPlugin.show(
      1,
      'Work Paused',
      'You are out of the work zone. Timer paused.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'work_status_channel',
          'Work Status',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  void _showResumedNotification() {
    flutterLocalNotificationsPlugin.show(
      2,
      'Work Resumed',
      'You are back in the work zone. Timer resumed.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'work_status_channel',
          'Work Status',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _locationTimer?.cancel();
    _photoTimer?.cancel();
    _workTimer?.cancel();
    _faceDetector?.close();
    _faceDetectedTimer?.cancel();
    super.dispose();
  }

  void _handleFaceDetection(Face? face) {
    setState(() {
      _isFaceDetected = face != null;
      if (_isFaceDetected) {
        _faceDetectedTimer?.cancel();
        _faceDetectedTimer = Timer(Duration(seconds: 1), () {
          setState(() {
            _isFaceDetected = false;
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text('Mark Attendance', style: TextStyle(color: _textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.mail_outline, color: _primaryColor),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isOffsite ? "Offsite Attendance" : "Onsite Attendance",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _textColor),
              ),
              SizedBox(height: 20),
              if (_isWithinRange) ...[
                Center(
                  child: FutureBuilder<void>(
                    future: _initializeControllerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 350,
                              width: 350,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black26, blurRadius: 10)
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: CameraPreview(_cameraController!),
                              ),
                            ),
                            if (widget.isOffsite)
                              Icon(
                                Icons.location_on,
                                size: 50,
                                color: Colors.white.withOpacity(0.7),
                              ),
                          ],
                        );
                      } else {
                        return CircularProgressIndicator();
                      }
                    },
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    _showFaceDetectedMessage
                        ? 'Face detected'
                        : 'No face detected',
                    style: TextStyle(
                      color:
                          _showFaceDetectedMessage ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ] else ...[
                Center(
                  child: Container(
                    height: 350,
                    width: 350,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        'Out of range\nCamera disabled',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(height: 20),
              Center(
                child: Text(
                  _isWithinRange
                      ? 'In range - Attendance active'
                      : 'Out of range - Attendance paused',
                  style: TextStyle(
                    color: _isWithinRange ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Spacer(),
              Text(
                _currentTime,
                style: TextStyle(color: _textColor, fontSize: 16),
              ),
              Text(
                widget.isOffsite
                    ? 'Offsite: $_locationInfo'
                    : 'Onsite: $_locationInfo',
                style: TextStyle(color: _primaryColor, fontSize: 14),
              ),
              if (_workStartTime != null)
                Text(
                  'Working since: ${DateFormat('HH:mm').format(_workStartTime!)}',
                  style: TextStyle(color: _primaryColor, fontSize: 14),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case "updateWorkTimer":
        await _updateWorkTimer();
        break;
    }
    return Future.value(true);
  });
}

Future<void> _updateWorkTimer() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int? startTime = prefs.getInt('workStartTime');

  if (startTime != null) {
    Duration workDuration = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(startTime));
    String formattedDuration = _formatDuration(workDuration);

    await _showBackgroundNotification(
        'Work Timer', 'Working time: $formattedDuration');
  }
}

String _formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
}

Future<void> _showBackgroundNotification(String title, String body) async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'work_timer_channel',
    'Work Timer',
    importance: Importance.max,
    priority: Priority.high,
    ongoing: true,
    autoCancel: false,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    platformChannelSpecifics,
  );
}
