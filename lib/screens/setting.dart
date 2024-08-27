import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onReset;

  SettingsScreen({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            onReset();
            Navigator.pop(context, true);
          },
          child: Text('Reset Today\'s Work'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 50),
            textStyle: TextStyle(fontSize: 18),
            foregroundColor: Colors.redAccent,
          ),
        ),
      ),
    );
  }
}
