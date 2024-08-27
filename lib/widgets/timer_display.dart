import 'package:flutter/material.dart';

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
