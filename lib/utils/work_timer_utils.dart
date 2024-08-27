import 'package:shared_preferences/shared_preferences.dart';

class WorkTimerUtils {
  DateTime? _workStartTime;

  Future<void> checkWorkStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? startTime = prefs.getInt('workStartTime');
    if (startTime != null) {
      _workStartTime = DateTime.fromMillisecondsSinceEpoch(startTime);
    }
  }

  // Add other work timer-related methods here
}
