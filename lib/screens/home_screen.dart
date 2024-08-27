import 'package:flutter/material.dart';
import 'dart:async';
import 'start_working_hour_screen.dart';
import 'setting.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Duration _duration = Duration.zero;
  bool _isWorking = false;
  Timer? _timer;
  DateTime? _workStartTime;
  bool _isDarkMode = false;
  bool _isWithinRange = true;

  late Color _primaryColor;
  late Color _accentColor;
  late Color _backgroundColor;
  late Color _textColor;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
    _checkWorkStatus();
    _initializeBackgroundTasks();
  }

  void _initializeBackgroundTasks() {
    Workmanager().initialize(callbackDispatcher);
    Workmanager().registerPeriodicTask(
      "locationCheck",
      "checkLocation",
      frequency: Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    );
  }

  void _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _updateThemeColors();
    });
  }

  void _updateThemeColors() {
    if (_isDarkMode) {
      _primaryColor = Colors.blue[700]!;
      _accentColor = Colors.blue[300]!;
      _backgroundColor = Colors.grey[900]!;
      _textColor = Colors.white;
    } else {
      _primaryColor = Colors.blue[700]!;
      _accentColor = Colors.blue[300]!;
      _backgroundColor = Colors.grey[100]!;
      _textColor = Colors.grey[800]!;
    }
  }

  void _toggleTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = !_isDarkMode;
      prefs.setBool('isDarkMode', _isDarkMode);
      _updateThemeColors();
    });
  }

  Future<void> _checkWorkStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? startTime = prefs.getInt('workStartTime');
    if (startTime != null) {
      setState(() {
        _isWorking = true;
        _workStartTime = DateTime.fromMillisecondsSinceEpoch(startTime);
      });
      _startTimer();
    }
    _checkLocation();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_workStartTime != null && _isWithinRange) {
        setState(() {
          _duration = DateTime.now().difference(_workStartTime!);
        });
      }
    });
  }

  void _resetTimer() async {
    setState(() {
      _isWorking = false;
      _duration = Duration.zero;
      _workStartTime = null;
    });
    _timer?.cancel();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('workStartTime');
  }

  Future<void> _checkLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      double workLat = 19.225364; // Replace with actual work location
      double workLong = 73.125803; // Replace with actual work location

      double distance = Geolocator.distanceBetween(
          position.latitude, position.longitude, workLat, workLong);

      bool newIsWithinRange = distance <= 200;
      if (_isWithinRange != newIsWithinRange) {
        setState(() {
          _isWithinRange = newIsWithinRange;
        });
        if (!_isWithinRange) {
          _pauseWork();
        } else {
          _resumeWork();
        }
      }
    } catch (e) {
      print('Error checking location: $e');
    }
  }

  void _pauseWork() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('workPausedTime', DateTime.now().millisecondsSinceEpoch);
  }

  void _resumeWork() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? pausedTime = prefs.getInt('workPausedTime');
    int? startTime = prefs.getInt('workStartTime');
    if (pausedTime != null && startTime != null) {
      int pausedDuration = DateTime.now().millisecondsSinceEpoch - pausedTime;
      int newStartTime = startTime + pausedDuration;
      await prefs.setInt('workStartTime', newStartTime);
      setState(() {
        _workStartTime = DateTime.fromMillisecondsSinceEpoch(newStartTime);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text('Welcome, Employee', style: TextStyle(color: _textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: _primaryColor),
            onPressed: _toggleTheme,
          ),
          IconButton(
            icon: Icon(Icons.settings, color: _primaryColor),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SettingsScreen(onReset: _resetTimer)),
              );
              if (result == true) {
                _resetTimer();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            GridView.count(
              crossAxisCount: 2,
              padding: EdgeInsets.all(20.0),
              crossAxisSpacing: 20.0,
              mainAxisSpacing: 20.0,
              children: <Widget>[
                if (!_isWorking)
                  _buildGridItem(Icons.access_time, 'Start Working Hour'),
                _buildGridItem(Icons.add_location_alt, 'Add New Workplace'),
                _buildGridItem(Icons.calendar_today, 'Attendance Summary'),
                _buildGridItem(Icons.assignment, 'Leave Application'),
              ],
            ),
            if (_isWorking)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: TimerDisplay(
                    duration: _duration,
                    isWorking: _isWorking,
                    isWithinRange: _isWithinRange,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(IconData icon, String title) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: _isDarkMode ? Colors.grey[800] : Colors.white,
      child: InkWell(
        onTap: () {
          if (title == 'Start Working Hour') {
            _showWorkLocationDialog();
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 50, color: _primaryColor),
            SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, color: _textColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showWorkLocationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Work Location'),
          content: Text('Are you working onsite or offsite?'),
          actions: <Widget>[
            TextButton(
              child: Text('Onsite'),
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToStartWorkingHour(isOffsite: false);
              },
            ),
            TextButton(
              child: Text('Offsite'),
              onPressed: () {
                Navigator.of(context).pop();
                _showOffsiteLocations();
              },
            ),
          ],
        );
      },
    );
  }

  void _showOffsiteLocations() {
    List<Map<String, dynamic>> offsiteLocations = [
      {'name': 'Aman Office', 'latitude': 19.225364, 'longitude': 73.125803},
      {'name': 'Coworking Space', 'latitude': 34.0522, 'longitude': -118.2437},
      {'name': 'Client Site', 'latitude': 51.5074, 'longitude': -0.1278},
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Offsite Location'),
          content: SingleChildScrollView(
            child: ListBody(
              children: offsiteLocations.map((location) {
                return ListTile(
                  title: Text(location['name']),
                  subtitle: Text(
                      'Lat: ${location['latitude']}, Long: ${location['longitude']}'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _navigateToStartWorkingHour(
                        isOffsite: true, offsiteLocation: location);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _navigateToStartWorkingHour(
      {required bool isOffsite, Map<String, dynamic>? offsiteLocation}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => StartWorkingHourScreen(
                isOffsite: isOffsite,
                offsiteLocation: offsiteLocation,
              )),
    );
    if (result == true) {
      _startTimer();
    }
  }
}

class TimerDisplay extends StatelessWidget {
  final Duration duration;
  final bool isWorking;
  final bool isWithinRange;

  TimerDisplay({
    required this.duration,
    required this.isWorking,
    required this.isWithinRange,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
        decoration: BoxDecoration(
          color: isWithinRange ? Colors.blue[700] : Colors.red[700],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          isWithinRange
              ? 'Working: ${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}'
              : 'Out of range - Work paused',
          style: TextStyle(
              fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case "checkLocation":
        await _checkLocationBackground();
        break;
    }
    return Future.value(true);
  });
}

Future<void> _checkLocationBackground() async {
  try {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    double workLat = 19.225364; // Replace with actual work location
    double workLong = 73.125803; // Replace with actual work location

    double distance = Geolocator.distanceBetween(
        position.latitude, position.longitude, workLat, workLong);

    bool isWithinRange = distance <= 200;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool wasWithinRange = prefs.getBool('isWithinRange') ?? true;

    if (isWithinRange != wasWithinRange) {
      await prefs.setBool('isWithinRange', isWithinRange);
      if (!isWithinRange) {
        await prefs.setInt(
            'workPausedTime', DateTime.now().millisecondsSinceEpoch);
      } else {
        int? pausedTime = prefs.getInt('workPausedTime');
        int? startTime = prefs.getInt('workStartTime');
        if (pausedTime != null && startTime != null) {
          int pausedDuration =
              DateTime.now().millisecondsSinceEpoch - pausedTime;
          int newStartTime = startTime + pausedDuration;
          await prefs.setInt('workStartTime', newStartTime);
        }
      }
    }
  } catch (e) {
    print('Error checking location in background: $e');
  }
}
